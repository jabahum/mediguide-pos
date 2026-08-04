/// Model representing an emergency or ministry contact
class ContactModel {
  final String id;
  final String name;
  final String title;
  final String department;
  final String phoneNumber;
  final String email;
  final String address;
  final ContactCategory category;
  final bool isEmergency;
  final bool isAvailable24h;
  final String description;
  final List<String> services;

  const ContactModel({
    required this.id,
    required this.name,
    required this.title,
    required this.department,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.category,
    required this.isEmergency,
    required this.isAvailable24h,
    required this.description,
    required this.services,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      department: json['department'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      category: ContactCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ContactCategory.general,
      ),
      isEmergency: json['isEmergency'] as bool,
      isAvailable24h: json['isAvailable24h'] as bool,
      description: json['description'] as String,
      services: List<String>.from(json['services'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'department': department,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'category': category.name,
      'isEmergency': isEmergency,
      'isAvailable24h': isAvailable24h,
      'description': description,
      'services': services,
    };
  }

  /// Display name combining name and title
  String get displayName => '$name - $title';

  /// Availability status text
  String get availabilityText =>
      isAvailable24h ? '24/7 Available' : 'Business Hours';

  /// Category icon based on contact category
  String get categoryIcon => category.icon;

  /// Priority level for sorting (emergency contacts first)
  int get priority => isEmergency ? 1 : category.priority;

  /// Primary service offered (first in services list)
  String get primaryService =>
      services.isNotEmpty ? services.first : 'General Support';

  /// Formatted phone number for display
  String get formattedPhoneNumber {
    // Simple formatting for display - can be enhanced based on region
    if (phoneNumber.length >= 10) {
      return '${phoneNumber.substring(0, 3)}-${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}';
    }
    return phoneNumber;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ContactModel{id: $id, name: $name, category: $category, isEmergency: $isEmergency}';
  }
}

/// Categories of contacts available in the system
enum ContactCategory {
  emergency(label: 'Emergency', icon: '🚨', priority: 2),
  ministry(label: 'Ministry', icon: '🏛️', priority: 3),
  regional(label: 'Regional', icon: '🏢', priority: 5),
  hospital(label: 'Hospital', icon: '🏥', priority: 4),
  general(label: 'General', icon: '📞', priority: 6);

  const ContactCategory({
    required this.label,
    required this.icon,
    required this.priority,
  });

  final String label;
  final String icon;
  final int priority;
}
