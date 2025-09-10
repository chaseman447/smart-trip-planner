import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WeatherData {
  final double latitude;
  final double longitude;
  final String timezone;
  final List<DailyWeather> dailyWeather;

  WeatherData({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.dailyWeather,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    final times = List<String>.from(daily['time']);
    final maxTemps = List<double>.from(daily['temperature_2m_max']);
    final minTemps = List<double>.from(daily['temperature_2m_min']);
    final precipitation = List<double>.from(daily['precipitation_sum']);

    final dailyWeather = <DailyWeather>[];
    for (int i = 0; i < times.length; i++) {
      dailyWeather.add(DailyWeather(
        date: times[i],
        maxTemp: maxTemps[i],
        minTemp: minTemps[i],
        precipitation: precipitation[i],
      ));
    }

    return WeatherData(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      timezone: json['timezone'] ?? 'UTC',
      dailyWeather: dailyWeather,
    );
  }
}

class DailyWeather {
  final String date;
  final double maxTemp;
  final double minTemp;
  final double precipitation;

  DailyWeather({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitation,
  });

  String get weatherSummary {
    final tempRange = '${minTemp.toInt()}°-${maxTemp.toInt()}°C';
    final precipText = precipitation > 0 ? ', ${precipitation.toInt()}mm rain' : '';
    return '$tempRange$precipText';
  }

  String get weatherIcon {
    if (precipitation > 10) return '🌧️';
    if (precipitation > 0) return '🌦️';
    if (maxTemp > 30) return '☀️';
    if (maxTemp > 20) return '⛅';
    return '☁️';
  }
}

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetch weather data for a location and date range
  /// [latitude] and [longitude] coordinates of the location
  /// [startDate] and [endDate] in YYYY-MM-DD format
  Future<WeatherData?> getWeatherForecast({
    required double latitude,
    required double longitude,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum',
        'start_date': startDate,
        'end_date': endDate,
        'timezone': 'auto',
      });

      print('Weather API Request: $uri');

      final response = await http.get(uri).timeout(_timeout);

      print('Weather API Response Status: ${response.statusCode}');
      print('Weather API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return WeatherData.fromJson(data);
      } else {
        print('Weather API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      print('Weather Service Network Error: $e');
      return null;
    } on http.ClientException catch (e) {
      print('Weather Service HTTP Error: $e');
      return null;
    } on FormatException catch (e) {
      print('Weather Service JSON Parse Error: $e');
      return null;
    } catch (e) {
      print('Weather Service Unexpected Error: $e');
      return null;
    }
  }

  /// Get weather for a single day
  Future<DailyWeather?> getDayWeather({
    required double latitude,
    required double longitude,
    required String date,
  }) async {
    final weatherData = await getWeatherForecast(
      latitude: latitude,
      longitude: longitude,
      startDate: date,
      endDate: date,
    );

    return weatherData?.dailyWeather.isNotEmpty == true
        ? weatherData!.dailyWeather.first
        : null;
  }

  /// Extract coordinates from location string (basic implementation)
  /// In a real app, you'd use a geocoding service
  Map<String, double>? parseCoordinates(String location) {
    // Basic coordinate extraction for common formats
    final coordRegex = RegExp(r'(-?\d+\.\d+),\s*(-?\d+\.\d+)');
    final match = coordRegex.firstMatch(location);
    
    if (match != null) {
      return {
        'latitude': double.parse(match.group(1)!),
        'longitude': double.parse(match.group(2)!),
      };
    }

    // Fallback coordinates for common cities (you can expand this)
    final cityCoords = {
      'tokyo': {'latitude': 35.6762, 'longitude': 139.6503},
      'kyoto': {'latitude': 35.0116, 'longitude': 135.7681},
      'osaka': {'latitude': 34.6937, 'longitude': 135.5023},
      'new york': {'latitude': 40.7128, 'longitude': -74.0060},
      'london': {'latitude': 51.5074, 'longitude': -0.1278},
      'paris': {'latitude': 48.8566, 'longitude': 2.3522},
    };

    final lowerLocation = location.toLowerCase();
    for (final city in cityCoords.keys) {
      if (lowerLocation.contains(city)) {
        return cityCoords[city];
      }
    }

    return null;
  }
}