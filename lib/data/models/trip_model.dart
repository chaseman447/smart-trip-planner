import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/chat_message.dart';

part 'trip_model.g.dart';

@HiveType(typeId: 0)
class TripModel extends HiveObject {
  @HiveField(0)
  late String tripId;
  
  @HiveField(1)
  late String title;
  
  @HiveField(8)
  String? description;
  
  @HiveField(2)
  late DateTime startDate;
  
  @HiveField(3)
  late DateTime endDate;
  
  @HiveField(4)
  late String daysJson; // Store serialized days as JSON string
  
  @HiveField(5)
  late DateTime createdAt;
  
  @HiveField(6)
  DateTime? updatedAt;
  
  @HiveField(7)
  int totalTokensUsed = 0;
  


  // Convert from domain entity
  static TripModel fromEntity(Trip trip) {
    return TripModel()
      ..tripId = trip.id
      ..title = trip.title
      ..description = trip.description

      ..startDate = trip.startDate
      ..endDate = trip.endDate
      ..daysJson = _serializeDays(trip.days)
      ..createdAt = trip.createdAt
      ..updatedAt = trip.updatedAt
      ..totalTokensUsed = trip.totalTokensUsed;
  }

  // Convert to domain entity
  Trip toEntity() {
    return Trip(
      id: tripId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      days: _deserializeDays(daysJson),
      createdAt: createdAt,
      updatedAt: updatedAt,
      totalTokensUsed: totalTokensUsed,
    );
  }

  static String _serializeDays(List<DayItinerary> days) {
    final List<Map<String, dynamic>> serialized = days.map((day) => day.toJson()).toList();
    return jsonEncode(serialized);
  }

  static List<DayItinerary> _deserializeDays(String daysJson) {
    final List<dynamic> decoded = jsonDecode(daysJson);
    return decoded.map((day) => DayItinerary.fromJson(day as Map<String, dynamic>)).toList();
  }
}

@HiveType(typeId: 1)
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  late String messageId;
  
  @HiveField(1)
  late String content;
  
  @HiveField(2)
  late ChatMessageTypeModel type;
  
  @HiveField(3)
  late DateTime timestamp;
  
  @HiveField(4)
  String? tripId;
  
  @HiveField(5)
  int? tokensUsed;
  
  @HiveField(6)
  bool isStreaming = false;

  // Convert from domain entity
  static ChatMessageModel fromEntity(ChatMessage message) {
    return ChatMessageModel()
      ..messageId = message.id
      ..content = message.content
      ..type = ChatMessageTypeModel.values.byName(message.type.name)
      ..timestamp = message.timestamp
      ..tripId = message.tripId
      ..tokensUsed = message.tokensUsed
      ..isStreaming = message.isStreaming;
  }

  // Convert to domain entity
  ChatMessage toEntity() {
    return ChatMessage(
      id: messageId,
      content: content,
      type: ChatMessageType.values.byName(type.name),
      timestamp: timestamp,
      tripId: tripId,
      tokensUsed: tokensUsed,
      isStreaming: isStreaming,
    );
  }
}

@HiveType(typeId: 2)
enum ChatMessageTypeModel {
  @HiveField(0)
  user,
  
  @HiveField(1)
  assistant,
  
  @HiveField(2)
  system,
  
  @HiveField(3)
  error,
}