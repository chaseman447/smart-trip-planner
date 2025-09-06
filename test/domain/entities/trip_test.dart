import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tri_planner/domain/entities/trip.dart';

void main() {
  group('Trip Entity Tests', () {
    late Trip testTrip;
    late DateTime startDate;
    late DateTime endDate;
    late List<DayItinerary> testDays;

    setUp(() {
      startDate = DateTime(2024, 3, 1);
      endDate = DateTime(2024, 3, 3);
      
      testDays = [
        DayItinerary(
          date: startDate,
          summary: 'Arrival and exploration',
          items: [
            ItineraryItem(
              time: '10:00',
              activity: 'Arrive at Tokyo Station',
              location: '35.6812,139.7671',
            ),
            ItineraryItem(
              time: '14:00',
              activity: 'Visit Shibuya Crossing',
              location: '35.6598,139.7006',
            ),
          ],
        ),
        DayItinerary(
          date: startDate.add(const Duration(days: 1)),
          summary: 'Cultural sites',
          items: [
            ItineraryItem(
              time: '09:00',
              activity: 'Visit Senso-ji Temple',
              location: '35.7148,139.7967',
            ),
          ],
        ),
      ];

      testTrip = Trip(
        id: 'test-trip-123',
        title: 'Tokyo Adventure',
        startDate: startDate,
        endDate: endDate,
        days: testDays,
        createdAt: DateTime.now(),
      );
    });

    test('should create Trip with all required properties', () {
      // Assert
      expect(testTrip.id, 'test-trip-123');
      expect(testTrip.title, 'Tokyo Adventure');
      expect(testTrip.startDate, startDate);
      expect(testTrip.endDate, endDate);
      expect(testTrip.days.length, 2);
      expect(testTrip.createdAt, isA<DateTime>());
    });

    test('should calculate correct trip duration', () {
      // Act
      final duration = testTrip.endDate.difference(testTrip.startDate).inDays + 1;
      
      // Assert
      expect(duration, 3); // 3 days total
    });

    test('should have correct number of days', () {
      // Assert
      expect(testTrip.days.length, 2);
      expect(testTrip.days[0].date, startDate);
      expect(testTrip.days[1].date, startDate.add(const Duration(days: 1)));
    });

    test('should have proper day summaries', () {
      // Assert
      expect(testTrip.days[0].summary, 'Arrival and exploration');
      expect(testTrip.days[1].summary, 'Cultural sites');
    });

    test('should contain correct itinerary items', () {
      // Assert
      expect(testTrip.days[0].items.length, 2);
      expect(testTrip.days[0].items[0].activity, 'Arrive at Tokyo Station');
      expect(testTrip.days[0].items[0].time, '10:00');
      expect(testTrip.days[0].items[0].location, '35.6812,139.7671');
      
      expect(testTrip.days[1].items.length, 1);
      expect(testTrip.days[1].items[0].activity, 'Visit Senso-ji Temple');
    });

    test('should support equality comparison', () {
      // Arrange
      final sameTrip = Trip(
        id: 'test-trip-123',
        title: 'Tokyo Adventure',
        startDate: startDate,
        endDate: endDate,
        days: testDays,
        createdAt: testTrip.createdAt,
      );

      final differentTrip = Trip(
        id: 'different-trip-456',
        title: 'Osaka Journey',
        startDate: startDate,
        endDate: endDate,
        days: [],
        createdAt: DateTime.now(),
      );

      // Assert
      expect(testTrip == sameTrip, isTrue);
      expect(testTrip == differentTrip, isFalse);
    });

    test('should support copying with modifications', () {
      // Act
      final modifiedTrip = testTrip.copyWith(
        title: 'Updated Tokyo Adventure',
        endDate: endDate.add(const Duration(days: 1)),
      );

      // Assert
      expect(modifiedTrip.id, testTrip.id);
      expect(modifiedTrip.title, 'Updated Tokyo Adventure');
      expect(modifiedTrip.startDate, testTrip.startDate);
      expect(modifiedTrip.endDate, endDate.add(const Duration(days: 1)));
      expect(modifiedTrip.days, testTrip.days);
    });

    test('should handle empty itinerary days', () {
      // Arrange
      final emptyTrip = Trip(
        id: 'empty-trip',
        title: 'Empty Trip',
        startDate: startDate,
        endDate: endDate,
        days: [],
        createdAt: DateTime.now(),
      );

      // Assert
      expect(emptyTrip.days.isEmpty, isTrue);
      expect(emptyTrip.title, 'Empty Trip');
    });

    test('should validate date consistency', () {
      // Assert - start date should be before or equal to end date
      expect(testTrip.startDate.isBefore(testTrip.endDate) || 
             testTrip.startDate.isAtSameMomentAs(testTrip.endDate), isTrue);
    });
  });
}