// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthProfileAdapter extends TypeAdapter<HealthProfile> {
  @override
  final int typeId = 0;

  @override
  HealthProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthProfile(
      name: fields[0] as String,
      dob: fields[1] as String,
      bloodType: fields[2] as String,
      allergies: (fields[3] as List).cast<String>(),
      emergencyContact: fields[4] as String,
      emergencyPhone: fields[5] as String,
      deviceId: fields[6] as String,
      chronicConditions: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HealthProfile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.dob)
      ..writeByte(2)
      ..write(obj.bloodType)
      ..writeByte(3)
      ..write(obj.allergies)
      ..writeByte(4)
      ..write(obj.emergencyContact)
      ..writeByte(5)
      ..write(obj.emergencyPhone)
      ..writeByte(6)
      ..write(obj.deviceId)
      ..writeByte(7)
      ..write(obj.chronicConditions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DetectionLogAdapter extends TypeAdapter<DetectionLog> {
  @override
  final int typeId = 1;

  @override
  DetectionLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetectionLog(
      id: fields[0] as String,
      timestamp: fields[1] as int,
      label: fields[2] as String,
      confidence: fields[3] as double,
      lat: fields[4] as double,
      lng: fields[5] as double,
      synced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DetectionLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.label)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.lat)
      ..writeByte(5)
      ..write(obj.lng)
      ..writeByte(6)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectionLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlertRecordAdapter extends TypeAdapter<AlertRecord> {
  @override
  final int typeId = 3;

  @override
  AlertRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertRecord(
      id: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      confidence: fields[3] as double,
      healthId: fields[4] as String,
      emergencyNum: fields[5] as String,
      timestamp: fields[6] as int,
      status: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AlertRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.healthId)
      ..writeByte(5)
      ..write(obj.emergencyNum)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
