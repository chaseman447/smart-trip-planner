import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_tri_planner/presentation/screens/chat_screen.dart';
import 'package:smart_tri_planner/domain/entities/chat_message.dart';

void main() {
  group('ChatScreen Widget Tests', () {
    testWidgets('should display basic chat interface elements', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should have proper app bar title', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('New Trip'), findsOneWidget);
    });

    testWidgets('should display clear chat action button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });

    testWidgets('should allow text input in chat field', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );
      
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Plan a trip to Tokyo');
      await tester.pump();

      // Assert
      expect(find.text('Plan a trip to Tokyo'), findsOneWidget);
    });

    testWidgets('should have scrollable chat area', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}