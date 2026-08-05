/// Context model for passing reference information to the assistant
class AiContext {
  final String title;
  final String content;
  final AiContextType sourceType;
  final String? sourceId;
  final Map<String, dynamic>? metadata;

  const AiContext({
    required this.title,
    required this.content,
    required this.sourceType,
    this.sourceId,
    this.metadata,
  });

  /// Create context for guideline pages
  factory AiContext.guideline({
    required String title,
    required String content,
    String? guidelineId,
    Map<String, dynamic>? metadata,
  }) {
    return AiContext(
      title: title,
      content: content,
      sourceType: AiContextType.guideline,
      sourceId: guidelineId,
      metadata: metadata,
    );
  }

  /// Create context for generic pages
  factory AiContext.genericPage({
    required String title,
    required String content,
    String? pageId,
    Map<String, dynamic>? metadata,
  }) {
    return AiContext(
      title: title,
      content: content,
      sourceType: AiContextType.genericPage,
      sourceId: pageId,
      metadata: metadata,
    );
  }

  /// Create context for drug details
  factory AiContext.drug({
    required String drugName,
    required String content,
    String? drugId,
    Map<String, dynamic>? metadata,
  }) {
    return AiContext(
      title: drugName,
      content: content,
      sourceType: AiContextType.drug,
      sourceId: drugId,
      metadata: metadata,
    );
  }

  /// Create context for medical calculators
  factory AiContext.calculator({
    required String calculatorName,
    required String content,
    String? calculatorId,
    Map<String, dynamic>? metadata,
  }) {
    return AiContext(
      title: calculatorName,
      content: content,
      sourceType: AiContextType.calculator,
      sourceId: calculatorId,
      metadata: metadata,
    );
  }

  /// Create context for medical tools
  factory AiContext.tool({
    required String toolName,
    required String content,
    String? toolId,
    Map<String, dynamic>? metadata,
  }) {
    return AiContext(
      title: toolName,
      content: content,
      sourceType: AiContextType.tool,
      sourceId: toolId,
      metadata: metadata,
    );
  }

  /// Create context for consultant profiles
  factory AiContext.consultant({
    required String consultantName,
    required String content,
    String? consultantId,
    Map<String, dynamic>? metadata,
  }) {
    return AiContext(
      title: consultantName,
      content: content,
      sourceType: AiContextType.consultant,
      sourceId: consultantId,
      metadata: metadata,
    );
  }

  /// Create context for health facilities
  factory AiContext.facility({
    required String facilityName,
    required String content,
    String? facilityId,
    Map<String, dynamic>? metadata,
  }) {
    return AiContext(
      title: facilityName,
      content: content,
      sourceType: AiContextType.facility,
      sourceId: facilityId,
      metadata: metadata,
    );
  }

  /// Create context for FAQ details
  factory AiContext.faq({
    required String question,
    required String answer,
    String? faqId,
    Map<String, dynamic>? metadata,
  }) {
    return AiContext(
      title: question,
      content: answer,
      sourceType: AiContextType.faq,
      sourceId: faqId,
      metadata: metadata,
    );
  }

  /// Convert to JSON for passing as navigation arguments
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'sourceType': sourceType.name,
      'sourceId': sourceId,
      'metadata': metadata,
    };
  }

  /// Create from JSON navigation arguments
  factory AiContext.fromJson(Map<String, dynamic> json) {
    return AiContext(
      title: json['title'] as String,
      content: json['content'] as String,
      sourceType: AiContextType.values.firstWhere(
        (type) => type.name == json['sourceType'],
        orElse: () => AiContextType.unknown,
      ),
      sourceId: json['sourceId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'AiContext(title: $title, sourceType: $sourceType, sourceId: $sourceId)';
  }
}

/// Types of contextual source data for different detail pages
enum AiContextType {
  guideline(
    label: 'Clinical Guideline',
    contextInstructions: 'Clinical guideline reference',
    icon: '📋',
  ),
  genericPage(
    label: 'Medical Information',
    contextInstructions: 'Medical reference content',
    icon: '📄',
  ),
  drug(
    label: 'Drug Information',
    contextInstructions: 'Pharmaceutical reference content',
    icon: '💊',
  ),
  calculator(
    label: 'Medical Calculator',
    contextInstructions: 'Medical calculation reference',
    icon: '🧮',
  ),
  tool(
    label: 'Medical Tool',
    contextInstructions: 'Medical tool or assessment reference',
    icon: '🔧',
  ),
  consultant(
    label: 'Medical Consultant',
    contextInstructions: 'Consultation reference information',
    icon: '👨‍⚕️',
  ),
  facility(
    label: 'Health Facility',
    contextInstructions: 'Health facility reference information',
    icon: '🏥',
  ),
  faq(
    label: 'FAQ',
    contextInstructions: 'Frequently asked question reference',
    icon: '❓',
  ),
  unknown(
    label: 'Information',
    contextInstructions: 'General medical reference information',
    icon: '📖',
  );

  const AiContextType({
    required this.label,
    required this.contextInstructions,
    required this.icon,
  });

  final String label;
  final String contextInstructions;
  final String icon;
}
