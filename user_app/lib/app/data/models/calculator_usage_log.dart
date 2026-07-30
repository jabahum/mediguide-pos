// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import '../enums/calculator_enums.dart';
import 'base_model.dart';
import 'user.dart';
import 'calculator.dart';

/// Calculator usage log model for tracking calculator/tool usage sessions
class CalculatorUsageLog extends BaseModel {
  CalculatorUsageLog(super.data);

  /// legacy collection API collection name
  static const String collection = 'calculator_usage_logs';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => CalculatorUsageLog(data));
    return true;
  })();

  /// Create CalculatorUsageLog from legacy collection API record
  static CalculatorUsageLog fromRecord(ApiRecord record) =>
      CalculatorUsageLog(record.data);

  /// Create JSON for new usage log record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String userId,
    required String calculatorId,
    required DateTime sessionStart,
    DateTime? sessionEnd,
    required CalculatorType calculatorType,
  }) {
    return {
      'user_id': userId,
      'calculator_id': calculatorId,
      'session_start': sessionStart.toIso8601String(),
      if (sessionEnd != null) 'session_end': sessionEnd.toIso8601String(),
      'calculator_type': _typeToString(calculatorType),
    };
  }

  /// Create JSON for updating session end time
  static Map<String, dynamic> forSessionEnd({required DateTime sessionEnd}) {
    return {'session_end': sessionEnd.toIso8601String()};
  }

  // Direct field properties
  late final String userId = get<String>("user_id", "");
  late final String calculatorId = get<String>("calculator_id", "");
  late final DateTime sessionStart =
      DateTime.tryParse(get<String>("session_start", "")) ?? DateTime.now();
  late final DateTime? sessionEnd = DateTime.tryParse(
    get<String>("session_end", ""),
  );

  // Enum properties with proper conversion
  late final CalculatorType calculatorType =
      _parseType(get<String>("calculator_type", "")) ??
      CalculatorType.calculator;

  // Relationship properties
  late final User? user = getRelation<User>("user_id");
  late final Calculator? calculator = getRelation<Calculator>("calculator_id");

  // Computed properties

  /// Get total duration in seconds (computed from session times)
  int get totalDurationSeconds {
    if (sessionEnd == null) {
      // If session is still active, calculate duration from start to now
      return DateTime.now().difference(sessionStart).inSeconds;
    }
    return sessionEnd!.difference(sessionStart).inSeconds;
  }

  /// Get total duration in minutes (computed)
  int get totalDurationMinutes => (totalDurationSeconds / 60).round();

  /// Get total duration in hours (computed)
  double get totalDurationHours => totalDurationSeconds / 3600;

  /// Get formatted duration string (e.g., "5m 30s", "1h 15m")
  String get durationFormatted {
    final seconds = totalDurationSeconds;

    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return remainingSeconds > 0
          ? '${minutes}m ${remainingSeconds}s'
          : '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final remainingMinutes = (seconds % 3600) ~/ 60;
      return remainingMinutes > 0
          ? '${hours}h ${remainingMinutes}m'
          : '${hours}h';
    }
  }

  /// Check if this is a valid/completed session
  bool get isValidSession => sessionEnd != null && totalDurationSeconds > 0;

  /// Check if the session is still active (no end time)
  bool get isActiveSession => sessionEnd == null;

  /// Check if session duration is longer than minimum threshold (30 seconds)
  bool get meetsMinimumDuration => totalDurationSeconds >= 30;

  /// Get session date (formatted)
  String get sessionDateFormatted {
    final now = DateTime.now();
    final sessionDate = DateTime(
      sessionStart.year,
      sessionStart.month,
      sessionStart.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${sessionStart.day}/${sessionStart.month}/${sessionStart.year}';
    }
  }

  /// Get session start time formatted (e.g., "2:30 PM")
  String get sessionTimeFormatted {
    final hour = sessionStart.hour > 12
        ? sessionStart.hour - 12
        : sessionStart.hour == 0
        ? 12
        : sessionStart.hour;
    final minute = sessionStart.minute.toString().padLeft(2, '0');
    final period = sessionStart.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Helper methods for enum conversion
  static String _typeToString(CalculatorType type) {
    switch (type) {
      case CalculatorType.calculator:
        return 'calculator';
      case CalculatorType.decisionTool:
        return 'decision_tool';
      case CalculatorType.checklist:
        return 'checklist';
    }
  }

  static CalculatorType? _parseType(String value) {
    switch (value.toLowerCase()) {
      case 'calculator':
        return CalculatorType.calculator;
      case 'decision_tool':
        return CalculatorType.decisionTool;
      case 'checklist':
        return CalculatorType.checklist;
      default:
        return null;
    }
  }
}
