// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripModelAdapter extends TypeAdapter<TripModel> {
  @override
  final int typeId = 0;

  @override
  TripModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripModel()
      ..tripId = fields[0] as String
      ..title = fields[1] as String
      ..description = fields[8] as String?
      ..startDate = fields[2] as DateTime
      ..endDate = fields[3] as DateTime
      ..daysJson = fields[4] as String
      ..createdAt = fields[5] as DateTime
      ..updatedAt = fields[6] as DateTime?
      ..totalTokensUsed = fields[7] as int;
  }

  @override
  void write(BinaryWriter writer, TripModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.tripId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.daysJson)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.totalTokensUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageModelAdapter extends TypeAdapter<ChatMessageModel> {
  @override
  final int typeId = 1;

  @override
  ChatMessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessageModel()
      ..messageId = fields[0] as String
      ..content = fields[1] as String
      ..type = fields[2] as ChatMessageTypeModel
      ..timestamp = fields[3] as DateTime
      ..tripId = fields[4] as String?
      ..tokensUsed = fields[5] as int?
      ..isStreaming = fields[6] as bool;
  }

  @override
  void write(BinaryWriter writer, ChatMessageModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.tripId)
      ..writeByte(5)
      ..write(obj.tokensUsed)
      ..writeByte(6)
      ..write(obj.isStreaming);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageTypeModelAdapter extends TypeAdapter<ChatMessageTypeModel> {
  @override
  final int typeId = 2;

  @override
  ChatMessageTypeModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChatMessageTypeModel.user;
      case 1:
        return ChatMessageTypeModel.assistant;
      case 2:
        return ChatMessageTypeModel.system;
      case 3:
        return ChatMessageTypeModel.error;
      default:
        return ChatMessageTypeModel.user;
    }
  }

  @override
  void write(BinaryWriter writer, ChatMessageTypeModel obj) {
    switch (obj) {
      case ChatMessageTypeModel.user:
        writer.writeByte(0);
        break;
      case ChatMessageTypeModel.assistant:
        writer.writeByte(1);
        break;
      case ChatMessageTypeModel.system:
        writer.writeByte(2);
        break;
      case ChatMessageTypeModel.error:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageTypeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
