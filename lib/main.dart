import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/app.dart';
import 'data/datasources/local_database.dart';
import 'core/services/vector_store_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for vector store
  await Hive.initFlutter();
  
  // Initialize the local database
  await LocalDatabase.initialize();
  
  // Initialize vector store
  final vectorStore = VectorStoreService();
  await vectorStore.initialize();
  
  runApp(
    const ProviderScope(
      child: SmartTripPlannerApp(),
    ),
  );
}
