/// Model representing application statistics displayed on home page
class StatsModel {
  final int drugsCount;
  final int guidelinesCount;
  final int healthcareFacilitiesCount;
  final int consultantsCount;
  final int patientsServedCount;
  final int emergencyContactsCount;
  final int faqsCount;
  final int unreadMessagesCount;
  final int userConversationsCount;
  final DateTime lastUpdated;

  const StatsModel({
    required this.drugsCount,
    required this.guidelinesCount,
    required this.healthcareFacilitiesCount,
    required this.consultantsCount,
    required this.patientsServedCount,
    required this.emergencyContactsCount,
    required this.faqsCount,
    required this.unreadMessagesCount,
    required this.userConversationsCount,
    required this.lastUpdated,
  });

  /// Create stats model with dummy data for development
  factory StatsModel.dummy() {
    return StatsModel(
      drugsCount: 2847,
      guidelinesCount: 156,
      healthcareFacilitiesCount: 842,
      consultantsCount: 128,
      patientsServedCount: 15640,
      emergencyContactsCount: 89,
      faqsCount: 45,
      unreadMessagesCount: 12,
      userConversationsCount: 8,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create stats model from JSON data
  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      drugsCount: json['drugsCount'] as int? ?? 0,
      guidelinesCount: json['guidelinesCount'] as int? ?? 0,
      healthcareFacilitiesCount: json['healthcareFacilitiesCount'] as int? ?? 0,
      consultantsCount: json['consultantsCount'] as int? ?? 0,
      patientsServedCount: json['patientsServedCount'] as int? ?? 0,
      emergencyContactsCount: json['emergencyContactsCount'] as int? ?? 0,
      faqsCount: json['faqsCount'] as int? ?? 0,
      unreadMessagesCount: json['unreadMessagesCount'] as int? ?? 0,
      userConversationsCount: json['userConversationsCount'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  /// Convert stats model to JSON
  Map<String, dynamic> toJson() {
    return {
      'drugsCount': drugsCount,
      'guidelinesCount': guidelinesCount,
      'healthcareFacilitiesCount': healthcareFacilitiesCount,
      'consultantsCount': consultantsCount,
      'patientsServedCount': patientsServedCount,
      'emergencyContactsCount': emergencyContactsCount,
      'faqsCount': faqsCount,
      'unreadMessagesCount': unreadMessagesCount,
      'userConversationsCount': userConversationsCount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Get formatted count with K/M suffixes
  String getFormattedCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Get formatted drug count
  String get formattedDrugsCount => getFormattedCount(drugsCount);

  /// Get formatted guidelines count
  String get formattedGuidelinesCount => getFormattedCount(guidelinesCount);

  /// Get formatted healthcare facilities count
  String get formattedHealthcareFacilitiesCount =>
      getFormattedCount(healthcareFacilitiesCount);

  /// Get formatted consultants count
  String get formattedConsultantsCount => getFormattedCount(consultantsCount);

  /// Get formatted patients served count
  String get formattedPatientsServedCount =>
      getFormattedCount(patientsServedCount);

  /// Get formatted emergency contacts count
  String get formattedEmergencyContactsCount =>
      getFormattedCount(emergencyContactsCount);

  /// Get formatted unread messages count
  String get formattedUnreadMessagesCount =>
      getFormattedCount(unreadMessagesCount);

  /// Get formatted user conversations count
  String get formattedUserConversationsCount =>
      getFormattedCount(userConversationsCount);

  /// Get formatted FAQs count
  String get formattedFaqsCount => getFormattedCount(faqsCount);

  @override
  String toString() {
    return 'StatsModel{drugs: $drugsCount, guidelines: $guidelinesCount, facilities: $healthcareFacilitiesCount, consultants: $consultantsCount, patients: $patientsServedCount, emergency: $emergencyContactsCount, faqs: $faqsCount, unreadMessages: $unreadMessagesCount, conversations: $userConversationsCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StatsModel &&
        other.drugsCount == drugsCount &&
        other.guidelinesCount == guidelinesCount &&
        other.healthcareFacilitiesCount == healthcareFacilitiesCount &&
        other.consultantsCount == consultantsCount &&
        other.patientsServedCount == patientsServedCount &&
        other.emergencyContactsCount == emergencyContactsCount &&
        other.faqsCount == faqsCount &&
        other.unreadMessagesCount == unreadMessagesCount &&
        other.userConversationsCount == userConversationsCount &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return drugsCount.hashCode ^
        guidelinesCount.hashCode ^
        healthcareFacilitiesCount.hashCode ^
        consultantsCount.hashCode ^
        patientsServedCount.hashCode ^
        emergencyContactsCount.hashCode ^
        faqsCount.hashCode ^
        unreadMessagesCount.hashCode ^
        userConversationsCount.hashCode ^
        lastUpdated.hashCode;
  }
}
