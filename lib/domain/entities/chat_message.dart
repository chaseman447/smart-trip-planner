import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required ChatMessageType type,
    required DateTime timestamp,
    String? tripId,
    int? tokensUsed,
    @Default(false) bool isStreaming,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

enum ChatMessageType {
  user,
  assistant,
  system,
  error,
}

@freezed
class ChatSession with _$ChatSession {
  const factory ChatSession({
    required String id,
    required List<ChatMessage> messages,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? tripId,
    @Default(0) int totalTokensUsed,
  }) = _ChatSession;

  factory ChatSession.fromJson(Map<String, dynamic> json) => _$ChatSessionFromJson(json);
}