import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/authentication/data/models/user.dart';

part 'support_ticket.freezed.dart';
part 'support_ticket.g.dart';

enum TicketStatus {
  open(label: 'Open', color: Colors.blue),
  inProgress(label: 'In Progress', color: Colors.orange),
  resolved(label: 'Resolved', color: Colors.green),
  closed(label: 'Closed', color: Colors.grey);

  const TicketStatus({required this.label, required this.color});
  final String label;
  final Color color;
}

enum TicketPriority {
  low(label: 'Low', color: Colors.grey),
  normal(label: 'Normal', color: Colors.blue),
  high(label: 'High', color: Colors.orange),
  urgent(label: 'Urgent', color: Colors.red);

  const TicketPriority({required this.label, required this.color});
  final String label;
  final Color color;
}

@freezed
abstract class SupportTicket with _$SupportTicket {
  const SupportTicket._();
  @JsonSerializable(explicitToJson: true)
  const factory SupportTicket({
    required String id,
    @Default('') String subject,
    @Default('') String description,
    @Default('') String category,
    @JsonKey(fromJson: _ticketStatusFromJson, toJson: _ticketStatusToJson)
    @Default(TicketStatus.open)
    TicketStatus status,
    @JsonKey(fromJson: _priorityFromJson, toJson: _priorityToJson)
    @Default(TicketPriority.normal)
    TicketPriority priority,
    @JsonKey(name: 'user_id') @Default('') String userId,
    @JsonKey(name: 'assigned_to') String? assignedTo,
    User? user,
    @JsonKey(name: 'assigned_user') User? assignedUser,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _SupportTicket;
  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);

  bool get isOpen => status == TicketStatus.open;
  bool get isInProgress => status == TicketStatus.inProgress;
  bool get isResolved => status == TicketStatus.resolved;
  bool get isClosed => status == TicketStatus.closed;
  bool get isActive => isOpen || isInProgress;
  bool get isUrgent => priority == TicketPriority.urgent;
  bool get isHighPriority => priority == TicketPriority.high || isUrgent;
  bool get isLowPriority => priority == TicketPriority.low;
  String get statusDisplay => status.label;
  String get priorityDisplay => priority.label;
  DateTime? get lastActivityDate => updatedAt ?? createdAt;
  bool isOwnedBy(String currentUserId) => userId == currentUserId;
  String get timeAgo {
    final activity = lastActivityDate;
    if (activity == null) return '';
    final difference = DateTime.now().difference(activity);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    return 'Just now';
  }
}

TicketStatus _ticketStatusFromJson(Object? value) =>
    switch (value?.toString()) {
      'in_progress' => TicketStatus.inProgress,
      'resolved' => TicketStatus.resolved,
      'closed' => TicketStatus.closed,
      _ => TicketStatus.open,
    };
String _ticketStatusToJson(TicketStatus value) =>
    value == TicketStatus.inProgress ? 'in_progress' : value.name;
TicketPriority _priorityFromJson(Object? value) =>
    TicketPriority.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => TicketPriority.normal,
    );
String _priorityToJson(TicketPriority value) => value.name;

@freezed
abstract class SupportTicketRequest with _$SupportTicketRequest {
  @JsonSerializable(includeIfNull: false)
  const factory SupportTicketRequest({
    String? subject,
    String? description,
    String? category,
    String? priority,
    String? status,
    @JsonKey(name: 'assigned_to') String? assignedTo,
  }) = _SupportTicketRequest;
  factory SupportTicketRequest.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketRequestFromJson(json);
}
