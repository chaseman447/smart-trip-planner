import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/app.dart';
import 'data/datasources/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the local database
  await LocalDatabase.initialize();
  
  runApp(
    const ProviderScope(
      child: SmartTripPlannerApp(),
    ),
  );
}
