// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';
import 'user.dart';

/// Status options for support tickets
enum TicketStatus {
  open(label: 'Open', color: Colors.blue),
  inProgress(label: 'In Progress', color: Colors.orange),
  resolved(label: 'Resolved', color: Colors.green),
  closed(label: 'Closed', color: Colors.grey);

  const TicketStatus({required this.label, required this.color});

  final String label;
  final Color color;
}

/// Priority levels for support tickets
enum TicketPriority {
  low(label: 'Low', color: Colors.grey),
  normal(label: 'Normal', color: Colors.blue),
  high(label: 'High', color: Colors.orange),
  urgent(label: 'Urgent', color: Colors.red);

  const TicketPriority({required this.label, required this.color});

  final String label;
  final Color color;
}

/// Support Ticket model for user help requests
class SupportTicket extends BaseModel {
  SupportTicket(super.data);

  /// legacy collection API collection name
  static const String collection = 'support_tickets';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => SupportTicket(data));
    return true;
  })();

  /// Create SupportTicket from legacy collection API record
  factory SupportTicket.fromRecord(ApiRecord record) {
    return SupportTicket(record.data);
  }

  // Core fields
  late final String subject = get<String>("subject", "");
  late final String description = get<String>("description", "");
  late final String category = get<String>("category", "");

  // Status and priority
  late final TicketStatus status =
      getEnum<TicketStatus>("status", TicketStatus.values) ?? TicketStatus.open;
  late final TicketPriority priority =
      getEnum<TicketPriority>("priority", TicketPriority.values) ??
      TicketPriority.normal;

  // User relations
  late final String userId = get<String>("user_id", "");
  late final String? assignedTo = get<String>("assigned_to");

  // Expanded relations
  User? get user => getRelation<User>("user_id");
  User? get assignedUser => getRelation<User>("assigned_to");

  // Status helpers
  bool get isOpen => status == TicketStatus.open;
  bool get isInProgress => status == TicketStatus.inProgress;
  bool get isResolved => status == TicketStatus.resolved;
  bool get isClosed => status == TicketStatus.closed;
  bool get isActive => isOpen || isInProgress;

  // Priority helpers
  bool get isUrgent => priority == TicketPriority.urgent;
  bool get isHighPriority =>
      priority == TicketPriority.high || priority == TicketPriority.urgent;
  bool get isLowPriority => priority == TicketPriority.low;

  // Display helpers using extensions
  String get statusDisplay => status.label;
  String get priorityDisplay => priority.label;

  // Get last activity date (just use created date for now)
  DateTime? get lastActivityDate => createdDate;

  // Check if user is the owner of this ticket
  bool isOwnedBy(String currentUserId) {
    return userId == currentUserId;
  }

  // Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final activity = lastActivityDate ?? createdDate;
    if (activity == null) return '';

    final difference = now.difference(activity);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'SupportTicket(id: $id, subject: $subject, status: $statusDisplay, priority: $priorityDisplay)';
  }
}
