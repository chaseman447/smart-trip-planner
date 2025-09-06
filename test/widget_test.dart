// Basic Flutter widget test for Smart Trip Planner app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_tri_planner/presentation/app.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartTripPlannerApp(),
      ),
    );

    // Verify that the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
