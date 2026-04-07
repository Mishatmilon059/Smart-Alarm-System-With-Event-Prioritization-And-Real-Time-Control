import 'package:flutter/material.dart';

enum EventType { alert, info, success }

class EventLog {
  final String message;
  final DateTime timestamp;
  final EventType type;

  EventLog({
    required this.message,
    required this.timestamp,
    required this.type,
  });

  Color get dotColor {
    switch (type) {
      case EventType.alert:
        return const Color(0xFFFF3B30);
      case EventType.info:
        return const Color(0xFF39FF14);
      case EventType.success:
        return const Color(0xFF39FF14);
    }
  }

  String get timeString {
    final now = timestamp.toUtc().add(const Duration(hours: 6));
    int hour12 = now.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final h = hour12.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$h:$m:$s $amPm';
  }
}
