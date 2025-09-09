import 'dart:math';
import 'package:logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeoPoint {
  final double latitude;
  final double longitude;
  final String? name;
  final String? id;

  GeoPoint({
    required this.latitude,
    required this.longitude,
    this.name,
    this.id,
  });

  @override
  String toString() => 'GeoPoint($latitude, $longitude, $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoPoint &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

class RouteSegment {
  final GeoPoint from;
  final GeoPoint to;
  final double distance;
  final double estimatedWalkingTime; // in minutes
  final String transportMode;

  RouteSegment({
    required this.from,
    required this.to,
    required this.distance,
    required this.estimatedWalkingTime,
    this.transportMode = 'walking',
  });
}

class OptimizedRoute {
  final List<GeoPoint> waypoints;
  final List<RouteSegment> segments;
  final double totalDistance;
  final double totalWalkingTime;
  final double efficiency; // 0-1 score

  OptimizedRoute({
    required this.waypoints,
    required this.segments,
    required this.totalDistance,
    required this.totalWalkingTime,
    required this.efficiency,
  });
}

class POIRanking {
  final GeoPoint poi;
  final double walkingDistance;
  final double walkingTime;
  final double priority;
  final Map<String, dynamic> metadata;

  POIRanking({
    required this.poi,
    required this.walkingDistance,
    required this.walkingTime,
    required this.priority,
    required this.metadata,
  });
}

class PathfindingService {
  final Logger _logger = Logger();
  
  // Average walking speed in km/h
  static const double _averageWalkingSpeed = 5.0;
  
  // Earth's radius in kilometers
  static const double _earthRadius = 6371.0;

  /// Calculate the Haversine distance between two points in kilometers
  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return _earthRadius * c;
  }

  /// Calculate estimated walking time in minutes
  double calculateWalkingTime(double distanceKm) {
    return (distanceKm / _averageWalkingSpeed) * 60;
  }

  /// Rank POIs by walking distance from a starting point
  List<POIRanking> rankPOIsByDistance({
    required GeoPoint startPoint,
    required List<GeoPoint> pois,
    Map<String, double>? priorityWeights,
    double maxWalkingDistance = 5.0, // km
  }) {
    final rankings = <POIRanking>[];

    for (final poi in pois) {
      final distance = calculateDistance(startPoint, poi);
      
      // Skip POIs that are too far
      if (distance > maxWalkingDistance) continue;
      
      final walkingTime = calculateWalkingTime(distance);
      
      // Calculate priority based on distance and optional weights
      double priority = 1.0 / (1.0 + distance); // Closer = higher priority
      
      if (priorityWeights != null && poi.id != null) {
        final weight = priorityWeights[poi.id!] ?? 1.0;
        priority *= weight;
      }

      rankings.add(POIRanking(
        poi: poi,
        walkingDistance: distance,
        walkingTime: walkingTime,
        priority: priority,
        metadata: {
          'distanceFromStart': distance,
          'walkingTimeMinutes': walkingTime,
          'isWalkable': distance <= 2.0, // Within 2km is considered walkable
        },
      ));
    }

    // Sort by priority (descending)
    rankings.sort((a, b) => b.priority.compareTo(a.priority));
    
    _logger.d('Ranked ${rankings.length} POIs by distance from start point');
    return rankings;
  }

  /// Optimize route using a simplified Traveling Salesman Problem approach
  OptimizedRoute optimizeRoute({
    required GeoPoint startPoint,
    required List<GeoPoint> waypoints,
    GeoPoint? endPoint,
    bool returnToStart = false,
  }) {
    if (waypoints.isEmpty) {
      return OptimizedRoute(
        waypoints: [startPoint],
        segments: [],
        totalDistance: 0.0,
        totalWalkingTime: 0.0,
        efficiency: 1.0,
      );
    }

    // Use nearest neighbor heuristic for TSP
    final optimizedWaypoints = _nearestNeighborTSP(
      startPoint,
      waypoints,
      endPoint,
      returnToStart,
    );

    // Calculate route segments
    final segments = <RouteSegment>[];
    double totalDistance = 0.0;

    for (int i = 0; i < optimizedWaypoints.length - 1; i++) {
      final from = optimizedWaypoints[i];
      final to = optimizedWaypoints[i + 1];
      final distance = calculateDistance(from, to);
      final walkingTime = calculateWalkingTime(distance);

      segments.add(RouteSegment(
        from: from,
        to: to,
        distance: distance,
        estimatedWalkingTime: walkingTime,
      ));

      totalDistance += distance;
    }

    final totalWalkingTime = calculateWalkingTime(totalDistance);
    final efficiency = _calculateRouteEfficiency(optimizedWaypoints, totalDistance);

    _logger.d('Optimized route with ${optimizedWaypoints.length} waypoints, '
        'total distance: ${totalDistance.toStringAsFixed(2)}km');

    return OptimizedRoute(
      waypoints: optimizedWaypoints,
      segments: segments,
      totalDistance: totalDistance,
      totalWalkingTime: totalWalkingTime,
      efficiency: efficiency,
    );
  }

  /// Find the optimal order to visit multiple POIs
  List<GeoPoint> findOptimalVisitOrder({
    required GeoPoint startPoint,
    required List<GeoPoint> pois,
    Map<String, int>? visitDurations, // in minutes
    int maxTotalTime = 480, // 8 hours in minutes
  }) {
    if (pois.isEmpty) return [startPoint];

    // Rank POIs by distance and priority
    final rankings = rankPOIsByDistance(startPoint: startPoint, pois: pois);
    
    // Select POIs that fit within time constraint
    final selectedPOIs = <GeoPoint>[];
    double totalTime = 0.0;

    for (final ranking in rankings) {
      final poi = ranking.poi;
      final walkingTime = ranking.walkingTime;
      final visitDuration = visitDurations?[poi.id] ?? 60; // Default 1 hour
      
      final timeNeeded = walkingTime + visitDuration;
      
      if (totalTime + timeNeeded <= maxTotalTime) {
        selectedPOIs.add(poi);
        totalTime += timeNeeded;
      }
    }

    // Optimize the route for selected POIs
    final optimizedRoute = optimizeRoute(
      startPoint: startPoint,
      waypoints: selectedPOIs,
    );

    return optimizedRoute.waypoints;
  }

  /// Get walking directions between two points (simplified)
  List<String> getWalkingDirections(GeoPoint from, GeoPoint to) {
    final distance = calculateDistance(from, to);
    final walkingTime = calculateWalkingTime(distance);
    
    // Calculate bearing
    final bearing = _calculateBearing(from, to);
    final direction = _bearingToDirection(bearing);
    
    return [
      'Head $direction from ${from.name ?? "start point"}',
      'Walk ${distance.toStringAsFixed(2)}km (${walkingTime.toStringAsFixed(0)} minutes)',
      'Arrive at ${to.name ?? "destination"}',
    ];
  }

  /// Calculate route efficiency (0-1 score)
  double _calculateRouteEfficiency(List<GeoPoint> waypoints, double totalDistance) {
    if (waypoints.length < 2) return 1.0;
    
    // Calculate direct distance from start to end
    final directDistance = calculateDistance(waypoints.first, waypoints.last);
    
    // Efficiency is inverse of detour ratio
    final detourRatio = totalDistance / max(directDistance, 0.1);
    return 1.0 / detourRatio;
  }

  /// Nearest neighbor TSP heuristic
  List<GeoPoint> _nearestNeighborTSP(
    GeoPoint startPoint,
    List<GeoPoint> waypoints,
    GeoPoint? endPoint,
    bool returnToStart,
  ) {
    final result = <GeoPoint>[startPoint];
    final remaining = List<GeoPoint>.from(waypoints);
    GeoPoint current = startPoint;

    while (remaining.isNotEmpty) {
      // Find nearest unvisited point
      GeoPoint? nearest;
      double minDistance = double.infinity;
      
      for (final point in remaining) {
        final distance = calculateDistance(current, point);
        if (distance < minDistance) {
          minDistance = distance;
          nearest = point;
        }
      }
      
      if (nearest != null) {
        result.add(nearest);
        remaining.remove(nearest);
        current = nearest;
      }
    }

    // Add end point if specified
    if (endPoint != null && endPoint != startPoint) {
      result.add(endPoint);
    } else if (returnToStart && result.last != startPoint) {
      result.add(startPoint);
    }

    return result;
  }

  /// Calculate bearing between two points
  double _calculateBearing(GeoPoint from, GeoPoint to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final deltaLon = (to.longitude - from.longitude) * pi / 180;

    final y = sin(deltaLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360; // Normalize to 0-360
  }

  /// Convert bearing to cardinal direction
  String _bearingToDirection(double bearing) {
    const directions = [
      'North', 'Northeast', 'East', 'Southeast',
      'South', 'Southwest', 'West', 'Northwest'
    ];
    
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Get route statistics
  Map<String, dynamic> getRouteStatistics(OptimizedRoute route) {
    return {
      'totalWaypoints': route.waypoints.length,
      'totalDistance': '${route.totalDistance.toStringAsFixed(2)} km',
      'totalWalkingTime': '${route.totalWalkingTime.toStringAsFixed(0)} minutes',
      'efficiency': '${(route.efficiency * 100).toStringAsFixed(1)}%',
      'averageSegmentDistance': route.segments.isNotEmpty 
          ? '${(route.totalDistance / route.segments.length).toStringAsFixed(2)} km'
          : '0 km',
      'longestSegment': route.segments.isNotEmpty
          ? '${route.segments.map((s) => s.distance).reduce(max).toStringAsFixed(2)} km'
          : '0 km',
      'shortestSegment': route.segments.isNotEmpty
          ? '${route.segments.map((s) => s.distance).reduce(min).toStringAsFixed(2)} km'
          : '0 km',
    };
  }
}

// Provider for PathfindingService
final pathfindingServiceProvider = Provider<PathfindingService>((ref) {
  return PathfindingService();
});