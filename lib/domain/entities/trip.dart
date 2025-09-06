import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<DayItinerary> days,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(0) int totalTokensUsed,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}

@freezed
class DayItinerary with _$DayItinerary {
  const factory DayItinerary({
    required DateTime date,
    required String summary,
    required List<ItineraryItem> items,
  }) = _DayItinerary;

  factory DayItinerary.fromJson(Map<String, dynamic> json) => _$DayItineraryFromJson(json);
}

@freezed
class ItineraryItem with _$ItineraryItem {
  const factory ItineraryItem({
    required String time,
    required String activity,
    required String location,
    String? description,
    String? mapUrl,
    @Default(false) bool isCompleted,
  }) = _ItineraryItem;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => _$ItineraryItemFromJson(json);
}