import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/generate_itinerary_usecase.dart';
import '../../core/errors/failures.dart';

part 'trip_provider.g.dart';

@riverpod
class TripNotifier extends _$TripNotifier {
  @override
  AsyncValue<Trip?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> generateItinerary(String userPrompt, {Trip? existingTrip}) async {
    state = const AsyncValue.loading();
    
    try {
      final useCase = ref.read(generateItineraryUseCaseProvider);
      final trip = await useCase.call(userPrompt, existingTrip: existingTrip);
      state = AsyncValue.data(trip);
    } on Failure catch (failure) {
      state = AsyncValue.error(failure, StackTrace.current);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveTrip(Trip trip) async {
    try {
      final useCase = ref.read(saveTripUseCaseProvider);
      await useCase.call(trip);
      // Refresh the trips list
      ref.invalidate(tripsListProvider);
    } on Failure catch (failure) {
      state = AsyncValue.error(failure, StackTrace.current);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      final useCase = ref.read(deleteTripUseCaseProvider);
      await useCase.call(tripId);
      // Refresh the trips list
      ref.invalidate(tripsListProvider);
      // Clear current trip if it was deleted
      if (state.value?.id == tripId) {
        state = const AsyncValue.data(null);
      }
    } on Failure catch (failure) {
      state = AsyncValue.error(failure, StackTrace.current);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void setTrip(Trip trip) {
    state = AsyncValue.data(trip);
  }

  void clearTrip() {
    state = const AsyncValue.data(null);
  }
}

@riverpod
Future<List<Trip>> tripsList(TripsListRef ref) async {
  final useCase = ref.read(getAllTripsUseCaseProvider);
  return await useCase.call();
}

@riverpod
Future<Trip?> tripById(TripByIdRef ref, String tripId) async {
  final useCase = ref.read(getTripByIdUseCaseProvider);
  return await useCase.call(tripId);
}

// Chat-related providers
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  List<ChatMessage> build() {
    return [];
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void updateLastMessage(ChatMessage message) {
    if (state.isNotEmpty) {
      final updatedMessages = [...state];
      updatedMessages[updatedMessages.length - 1] = message;
      state = updatedMessages;
    }
  }

  void clearMessages() {
    state = [];
  }

  void removeMessage(String messageId) {
    state = state.where((message) => message.id != messageId).toList();
  }
}

// Streaming provider for real-time itinerary generation
@riverpod
class ItineraryStreamNotifier extends _$ItineraryStreamNotifier {
  @override
  AsyncValue<String> build() {
    return const AsyncValue.data('');
  }

  Stream<String> generateItineraryStream(String userPrompt, {Trip? existingTrip}) async* {
    try {
      state = const AsyncValue.loading();
      final useCase = ref.read(generateItineraryUseCaseProvider);
      
      await for (final chunk in useCase.callStream(userPrompt, existingTrip: existingTrip)) {
        state = AsyncValue.data(chunk);
        yield chunk;
      }
    } on Failure catch (failure) {
      state = AsyncValue.error(failure, StackTrace.current);
      rethrow;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void reset() {
    state = const AsyncValue.data('');
  }
}

// UI state providers
@riverpod
class UiStateNotifier extends _$UiStateNotifier {
  @override
  UiState build() {
    return const UiState();
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setOfflineMode(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }
}

class UiState {
  final bool isLoading;
  final String? error;
  final bool isOffline;

  const UiState({
    this.isLoading = false,
    this.error,
    this.isOffline = false,
  });

  UiState copyWith({
    bool? isLoading,
    String? error,
    bool? isOffline,
  }) {
    return UiState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}