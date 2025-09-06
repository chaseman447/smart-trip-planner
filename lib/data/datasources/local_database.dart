import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../../core/errors/failures.dart';

class LocalDatabase {
  static const String _tripsBoxName = 'trips';
  static const String _messagesBoxName = 'messages';
  
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(TripModelAdapter());
    Hive.registerAdapter(ChatMessageModelAdapter());
    Hive.registerAdapter(ChatMessageTypeModelAdapter());
    
    _initialized = true;
  }
  
  static Future<Box<TripModel>> get _tripsBox async {
    await initialize();
    return await Hive.openBox<TripModel>(_tripsBoxName);
  }
  
  static Future<Box<ChatMessageModel>> get _messagesBox async {
    await initialize();
    return await Hive.openBox<ChatMessageModel>(_messagesBoxName);
  }

  // Trip operations
  Future<void> saveTrip(TripModel trip) async {
    try {
      final box = await _tripsBox;
      await box.put(trip.tripId, trip);
    } catch (e) {
      throw const Failure.database(message: 'Failed to save trip');
    }
  }

  Future<List<TripModel>> getAllTrips() async {
    try {
      final box = await _tripsBox;
      return box.values.toList();
    } catch (e) {
      throw const Failure.database(message: 'Failed to load trips');
    }
  }

  Future<TripModel?> getTripById(String tripId) async {
    try {
      final box = await _tripsBox;
      return box.get(tripId);
    } catch (e) {
      throw const Failure.database(message: 'Failed to load trip');
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      final box = await _tripsBox;
      await box.delete(tripId);
    } catch (e) {
      throw const Failure.database(message: 'Failed to delete trip');
    }
  }

  // Chat message operations
  Future<void> saveChatMessage(ChatMessageModel message) async {
    try {
      final box = await _messagesBox;
      await box.put(message.messageId, message);
    } catch (e) {
      throw const Failure.database(message: 'Failed to save chat message');
    }
  }

  Future<List<ChatMessageModel>> getChatMessagesForTrip(String? tripId) async {
    try {
      final box = await _messagesBox;
      if (tripId == null) {
        return box.values.toList();
      }
      return box.values.where((message) => message.tripId == tripId).toList();
    } catch (e) {
      throw const Failure.database(message: 'Failed to load chat messages');
    }
  }

  Future<void> deleteChatMessagesForTrip(String tripId) async {
    try {
      final box = await _messagesBox;
      final keysToDelete = <String>[];
      for (final entry in box.toMap().entries) {
        if (entry.value.tripId == tripId) {
          keysToDelete.add(entry.key);
        }
      }
      await box.deleteAll(keysToDelete);
    } catch (e) {
      throw const Failure.database(message: 'Failed to delete chat messages');
    }
  }

  Future<void> clearAllData() async {
    try {
      final tripsBox = await _tripsBox;
      final messagesBox = await _messagesBox;
      await tripsBox.clear();
      await messagesBox.clear();
    } catch (e) {
      throw const Failure.database(message: 'Failed to clear database');
    }
  }
}

// Provider for LocalDatabase
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});