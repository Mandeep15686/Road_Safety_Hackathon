import 'package:hive/hive.dart';
part 'health_model.g.dart';

// ─── Health Profile ───────────────────────────────────────────────────────────
@HiveType(typeId: 0)
class HealthProfile extends HiveObject {
  @HiveField(0) String name;
  @HiveField(1) String dob;
  @HiveField(2) String bloodType;
  @HiveField(3) List<String> allergies;
  @HiveField(4) String emergencyContact;
  @HiveField(5) String emergencyPhone;
  @HiveField(6) String deviceId;
  @HiveField(7) List<String> chronicConditions;

  HealthProfile({
    required this.name, required this.dob, required this.bloodType,
    required this.allergies, required this.emergencyContact,
    required this.emergencyPhone, required this.deviceId,
    this.chronicConditions = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'dob': dob, 'blood_type': bloodType,
    'allergies': allergies, 'emergency_contact': emergencyContact,
    'em_phone': emergencyPhone, 'device_id': deviceId,
    'chronic_conditions': chronicConditions,
  };
}

// ─── Detection Log ────────────────────────────────────────────────────────────
@HiveType(typeId: 1)
class DetectionLog extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) int timestamp;
  @HiveField(2) String label;
  @HiveField(3) double confidence;
  @HiveField(4) double lat;
  @HiveField(5) double lng;
  @HiveField(6) bool synced;

  DetectionLog({
    required this.id, required this.timestamp, required this.label,
    required this.confidence, required this.lat, required this.lng,
    this.synced = true,
  });
}

// ─── Alert Queue (kept for compatibility, now unused for offline) ─────────────
@HiveType(typeId: 2)
class AlertQueueItem extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String payload;
  @HiveField(2) String status;
  @HiveField(3) int retries;
  @HiveField(4) int createdAt;

  AlertQueueItem({
    required this.id, required this.payload,
    this.status = 'pending', this.retries = 0, required this.createdAt,
  });
}

// ─── Alert Record (NEW — replaces backend alerts table) ──────────────────────
@HiveType(typeId: 3)
class AlertRecord extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) double latitude;
  @HiveField(2) double longitude;
  @HiveField(3) double confidence;
  @HiveField(4) String healthId;
  @HiveField(5) String emergencyNum;
  @HiveField(6) int timestamp;
  @HiveField(7) String status;

  AlertRecord({
    required this.id, required this.latitude, required this.longitude,
    required this.confidence, required this.healthId,
    required this.emergencyNum, required this.timestamp,
    this.status = 'dispatched',
  });
}
