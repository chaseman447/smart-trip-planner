import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';
import '../../data/repositories/trip_repository_impl.dart';

class GenerateItineraryUseCase {
  final TripRepository _repository;

  GenerateItineraryUseCase(this._repository);

  Future<Trip> call(String userPrompt, {Trip? existingTrip}) async {
    return await _repository.generateItinerary(userPrompt, existingTrip: existingTrip);
  }

  Stream<String> callStream(String userPrompt, {Trip? existingTrip}) {
    return _repository.generateItineraryStream(userPrompt, existingTrip: existingTrip);
  }
}

class SaveTripUseCase {
  final TripRepository _repository;

  SaveTripUseCase(this._repository);

  Future<void> call(Trip trip) async {
    return await _repository.saveTrip(trip);
  }
}

class GetAllTripsUseCase {
  final TripRepository _repository;

  GetAllTripsUseCase(this._repository);

  Future<List<Trip>> call() async {
    return await _repository.getAllTrips();
  }
}

class GetTripByIdUseCase {
  final TripRepository _repository;

  GetTripByIdUseCase(this._repository);

  Future<Trip?> call(String tripId) async {
    return await _repository.getTripById(tripId);
  }
}

class DeleteTripUseCase {
  final TripRepository _repository;

  DeleteTripUseCase(this._repository);

  Future<void> call(String tripId) async {
    return await _repository.deleteTrip(tripId);
  }
}

class SearchWebUseCase {
  final TripRepository _repository;

  SearchWebUseCase(this._repository);

  Future<String> call(String query) async {
    return await _repository.searchWeb(query);
  }
}

// Providers for use cases
final generateItineraryUseCaseProvider = Provider<GenerateItineraryUseCase>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  return GenerateItineraryUseCase(repository);
});

final saveTripUseCaseProvider = Provider<SaveTripUseCase>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  return SaveTripUseCase(repository);
});

final getAllTripsUseCaseProvider = Provider<GetAllTripsUseCase>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  return GetAllTripsUseCase(repository);
});

final getTripByIdUseCaseProvider = Provider<GetTripByIdUseCase>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  return GetTripByIdUseCase(repository);
});

final deleteTripUseCaseProvider = Provider<DeleteTripUseCase>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  return DeleteTripUseCase(repository);
});

final searchWebUseCaseProvider = Provider<SearchWebUseCase>((ref) {
  final repository = ref.read(tripRepositoryProvider);
  return SearchWebUseCase(repository);
});