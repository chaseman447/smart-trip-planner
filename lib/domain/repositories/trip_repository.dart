import '../entities/trip.dart';

abstract class TripRepository {
  Future<Trip> generateItinerary(String userPrompt, {Trip? existingTrip});
  Stream<String> generateItineraryStream(String userPrompt, {Trip? existingTrip});
  Future<void> saveTrip(Trip trip);
  Future<List<Trip>> getAllTrips();
  Future<Trip?> getTripById(String tripId);
  Future<void> deleteTrip(String tripId);
  Future<String> searchWeb(String query);
}