// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TripImpl _$$TripImplFromJson(Map<String, dynamic> json) => _$TripImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      days: (json['days'] as List<dynamic>)
          .map((e) => DayItinerary.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      totalTokensUsed: (json['totalTokensUsed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TripImplToJson(_$TripImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'days': instance.days,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'totalTokensUsed': instance.totalTokensUsed,
    };

_$DayItineraryImpl _$$DayItineraryImplFromJson(Map<String, dynamic> json) =>
    _$DayItineraryImpl(
      date: DateTime.parse(json['date'] as String),
      summary: json['summary'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DayItineraryImplToJson(_$DayItineraryImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'summary': instance.summary,
      'items': instance.items,
    };

_$ItineraryItemImpl _$$ItineraryItemImplFromJson(Map<String, dynamic> json) =>
    _$ItineraryItemImpl(
      time: json['time'] as String,
      activity: json['activity'] as String,
      location: json['location'] as String,
      description: json['description'] as String?,
      mapUrl: json['mapUrl'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$ItineraryItemImplToJson(_$ItineraryItemImpl instance) =>
    <String, dynamic>{
      'time': instance.time,
      'activity': instance.activity,
      'location': instance.location,
      'description': instance.description,
      'mapUrl': instance.mapUrl,
      'isCompleted': instance.isCompleted,
    };
