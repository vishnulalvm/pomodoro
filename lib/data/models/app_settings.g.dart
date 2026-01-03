// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      id: fields[0] as int?,
      pomodoroDurationMinutes: fields[1] as int,
      restDurationMinutes: fields[2] as int,
      longRestDurationMinutes: fields[3] as int,
      soundEnabled: fields[4] as bool,
      pomodorosUntilLongRest: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pomodoroDurationMinutes)
      ..writeByte(2)
      ..write(obj.restDurationMinutes)
      ..writeByte(3)
      ..write(obj.longRestDurationMinutes)
      ..writeByte(4)
      ..write(obj.soundEnabled)
      ..writeByte(5)
      ..write(obj.pomodorosUntilLongRest);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
