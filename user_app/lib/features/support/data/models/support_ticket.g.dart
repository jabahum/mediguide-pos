// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SupportTicket _$SupportTicketFromJson(Map<String, dynamic> json) =>
    _SupportTicket(
      id: json['id'] as String,
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      status: json['status'] == null
          ? TicketStatus.open
          : _ticketStatusFromJson(json['status']),
      priority: json['priority'] == null
          ? TicketPriority.normal
          : _priorityFromJson(json['priority']),
      userId: json['user_id'] as String? ?? '',
      assignedTo: json['assigned_to'] as String?,
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      assignedUser: json['assigned_user'] == null
          ? null
          : User.fromJson(json['assigned_user'] as Map<String, dynamic>),
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$SupportTicketToJson(
  _SupportTicket instance,
) => <String, dynamic>{
  'id': instance.id,
  'subject': instance.subject,
  'description': instance.description,
  'category': instance.category,
  'status': _ticketStatusToJson(instance.status),
  'priority': _priorityToJson(instance.priority),
  'user_id': instance.userId,
  'assigned_to': instance.assignedTo,
  'user': instance.user?.toJson(),
  'assigned_user': instance.assignedUser?.toJson(),
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_SupportTicketRequest _$SupportTicketRequestFromJson(
  Map<String, dynamic> json,
) => _SupportTicketRequest(
  subject: json['subject'] as String?,
  description: json['description'] as String?,
  category: json['category'] as String?,
  priority: json['priority'] as String?,
  status: json['status'] as String?,
  assignedTo: json['assigned_to'] as String?,
);

Map<String, dynamic> _$SupportTicketRequestToJson(
  _SupportTicketRequest instance,
) => <String, dynamic>{
  if (instance.subject case final value?) 'subject': value,
  if (instance.description case final value?) 'description': value,
  if (instance.category case final value?) 'category': value,
  if (instance.priority case final value?) 'priority': value,
  if (instance.status case final value?) 'status': value,
  if (instance.assignedTo case final value?) 'assigned_to': value,
};
