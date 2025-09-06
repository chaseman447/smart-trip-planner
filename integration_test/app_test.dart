import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_tri_planner/presentation/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Trip Planner Integration Tests', () {
    testWidgets('Complete app flow test', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(
        const ProviderScope(
          child: SmartTripPlannerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify home screen loads
      expect(find.text('Smart Trip Planner'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Tap the add button to start a new trip
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify chat screen opens
      expect(find.text('New Trip'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Enter a trip planning message
      await tester.enterText(
        find.byType(TextField),
        'Plan a 3-day trip to Tokyo with cultural sites and modern attractions',
      );
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(
        find.text('Plan a 3-day trip to Tokyo with cultural sites and modern attractions'),
        findsOneWidget,
      );

      // Tap send button (note: this will fail in integration test without real API)
      // We're just testing the UI flow here
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Test clear chat functionality
      await tester.tap(find.byIcon(Icons.clear_all));
      await tester.pumpAndSettle();

      // Verify chat is cleared (text field should be empty)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text ?? '', isEmpty);
    });

    testWidgets('Navigation test', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(
        const ProviderScope(
          child: SmartTripPlannerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on home screen
      expect(find.text('Smart Trip Planner'), findsOneWidget);

      // Navigate to new trip
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify we're on chat screen
      expect(find.text('New Trip'), findsOneWidget);

      // Go back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back on home screen
      expect(find.text('Smart Trip Planner'), findsOneWidget);
    });

    testWidgets('UI responsiveness test', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(
        const ProviderScope(
          child: SmartTripPlannerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Test multiple rapid taps
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      // Verify app is still responsive
      expect(find.text('Smart Trip Planner'), findsOneWidget);
    });

    testWidgets('Text input validation test', (WidgetTester tester) async {
      // Launch the app and navigate to chat
      await tester.pumpWidget(
        const ProviderScope(
          child: SmartTripPlannerApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Test various text inputs
      final testInputs = [
        'Short trip',
        'Plan a very long detailed trip to multiple destinations with lots of activities and specific requirements for accommodation and transportation',
        '🗾 Trip to Japan with emojis! 🍣🏯',
        'Trip with numbers: 3 days, 5 cities, 10 attractions',
      ];

      for (final input in testInputs) {
        await tester.enterText(find.byType(TextField), input);
        await tester.pumpAndSettle();
        
        // Verify text was entered correctly
        expect(find.text(input), findsOneWidget);
        
        // Clear the field
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();
      }
    });
  });
}