// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      content: json['content'] as String,
      type: $enumDecode(_$ChatMessageTypeEnumMap, json['type']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      tripId: json['tripId'] as String?,
      tokensUsed: (json['tokensUsed'] as num?)?.toInt(),
      isStreaming: json['isStreaming'] as bool? ?? false,
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'type': _$ChatMessageTypeEnumMap[instance.type]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'tripId': instance.tripId,
      'tokensUsed': instance.tokensUsed,
      'isStreaming': instance.isStreaming,
    };

const _$ChatMessageTypeEnumMap = {
  ChatMessageType.user: 'user',
  ChatMessageType.assistant: 'assistant',
  ChatMessageType.system: 'system',
  ChatMessageType.error: 'error',
};

_$ChatSessionImpl _$$ChatSessionImplFromJson(Map<String, dynamic> json) =>
    _$ChatSessionImpl(
      id: json['id'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      tripId: json['tripId'] as String?,
      totalTokensUsed: (json['totalTokensUsed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ChatSessionImplToJson(_$ChatSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'messages': instance.messages,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'tripId': instance.tripId,
      'totalTokensUsed': instance.totalTokensUsed,
    };
