// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroSessionAdapter extends TypeAdapter<PomodoroSession> {
  @override
  final int typeId = 0;

  @override
  PomodoroSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroSession(
      id: fields[0] as int?,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      durationMinutes: fields[3] as int,
      mode: fields[4] as PomodoroMode,
      completed: fields[5] as bool,
      taskId: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroSession obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.mode)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.taskId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PomodoroModeAdapter extends TypeAdapter<PomodoroMode> {
  @override
  final int typeId = 1;

  @override
  PomodoroMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PomodoroMode.pomodoro;
      case 1:
        return PomodoroMode.rest;
      case 2:
        return PomodoroMode.longRest;
      default:
        return PomodoroMode.pomodoro;
    }
  }

  @override
  void write(BinaryWriter writer, PomodoroMode obj) {
    switch (obj) {
      case PomodoroMode.pomodoro:
        writer.writeByte(0);
        break;
      case PomodoroMode.rest:
        writer.writeByte(1);
        break;
      case PomodoroMode.longRest:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
