class SensorData {
  final bool pirMotion; // V0: true = motion detected
  final bool flameSensor; // V1: true = fire detected
  final bool doorSensor; // V2: true = door open
  final DateTime timestamp;

  SensorData({
    required this.pirMotion,
    required this.flameSensor,
    required this.doorSensor,
    required this.timestamp,
  });

  /// Whether any sensor is in alert state
  bool get hasAlert => pirMotion || flameSensor || doorSensor;

  /// Whether specifically a fire alert
  bool get hasFireAlert => flameSensor;

  /// Human-readable status
  String get systemStatus {
    if (flameSensor) return 'BREACH DETECTED';
    if (pirMotion) return 'MOTION ALERT';
    if (doorSensor) return 'DOOR OPENED';
    return 'SYSTEM SAFE';
  }

  String get statusDescription {
    if (flameSensor) {
      return 'Emergency protocol initiated. Fire sensors triggered. Local authorities notified.';
    }
    if (pirMotion) {
      return 'Motion detected in monitored zone. Review camera feed for verification.';
    }
    if (doorSensor) {
      return 'Door sensor triggered. Unauthorized entry may be in progress.';
    }
    return 'All sensors nominal. No threats detected. System operating normally.';
  }

  factory SensorData.offline() {
    return SensorData(
      pirMotion: false,
      flameSensor: false,
      doorSensor: false,
      timestamp: DateTime.now(),
    );
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      pirMotion: (int.tryParse('${json['v0'] ?? 0}') ?? 0) == 1,
      flameSensor: (int.tryParse('${json['v1'] ?? 0}') ?? 0) == 1,
      // Door sensor is active-low: 0 means OPEN, 1 means CLOSED. Default to 1 (Closed) if null.
      doorSensor: (int.tryParse('${json['v2'] ?? 1}') ?? 1) == 0,
      timestamp: DateTime.now(),
    );
  }
}
