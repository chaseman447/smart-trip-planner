import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/local_database.dart';
import '../datasources/ai_agent_service.dart';
import '../../core/services/enhanced_ai_agent_service.dart';
import '../models/trip_model.dart';

class TripRepositoryImpl implements TripRepository {
  final LocalDatabase _localDatabase;
  final EnhancedAIAgentService _enhancedAiAgentService;

  TripRepositoryImpl(this._localDatabase, this._enhancedAiAgentService);

  @override
  Future<Trip> generateItinerary(String userPrompt, {Trip? existingTrip}) async {
    try {
      final trip = await _enhancedAiAgentService.generateEnhancedItinerary(userPrompt, existingTrip: existingTrip);
      return trip;
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw Failure.unknown(message: e.toString());
    }
  }

  @override
  Stream<String> generateItineraryStream(String userPrompt, {Trip? existingTrip}) {
    try {
      // Convert user prompt to chat messages for the enhanced service
      final messages = [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: userPrompt,
          type: ChatMessageType.user,
          timestamp: DateTime.now(),
        )
      ];
      return _enhancedAiAgentService.chatWithTools(messages);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw Failure.unknown(message: e.toString());
    }
  }

  @override
  Future<void> saveTrip(Trip trip) async {
    try {
      final tripModel = TripModel.fromEntity(trip);
      await _localDatabase.saveTrip(tripModel);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw Failure.database(message: e.toString());
    }
  }

  @override
  Future<List<Trip>> getAllTrips() async {
    try {
      final tripModels = await _localDatabase.getAllTrips();
      return tripModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw Failure.database(message: e.toString());
    }
  }

  @override
  Future<Trip?> getTripById(String tripId) async {
    try {
      final tripModel = await _localDatabase.getTripById(tripId);
      return tripModel?.toEntity();
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw Failure.database(message: e.toString());
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      await _localDatabase.deleteTrip(tripId);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw Failure.database(message: e.toString());
    }
  }

  @override
  Future<String> searchWeb(String query) async {
    try {
      // Enhanced AI agent service handles web search internally
      final messages = [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: query,
          type: ChatMessageType.user,
          timestamp: DateTime.now(),
        )
      ];
      final responseStream = _enhancedAiAgentService.chatWithTools(messages);
      final buffer = StringBuffer();
      await for (final chunk in responseStream) {
        buffer.write(chunk);
      }
      return buffer.toString();
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw Failure.network(message: e.toString());
    }
  }
}

// Provider for TripRepositoryImpl
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final localDatabase = ref.read(localDatabaseProvider);
  final enhancedAiAgentService = ref.read(enhancedAIAgentServiceProvider);
  return TripRepositoryImpl(localDatabase, enhancedAiAgentService);
});