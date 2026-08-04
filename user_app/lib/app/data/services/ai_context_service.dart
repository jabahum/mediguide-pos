import '../models/ai_context.dart';

/// Service for formatting contextual assistant input
class AiContextService {
  /// Initialize the service with proper async pattern
  Future<AiContextService> init() async {
    return this;
  }

  /// Build contextual instructions for the assistant request
  String buildContextInstructions(AiContext context) {
    final instructions =
        '''
Use the following reference material when it is relevant to the user's question.

Context type: ${context.sourceType.contextInstructions}
Title: ${context.title}

Reference content:
${_formatContextContent(context)}

Response requirements:
- Keep the answer concise and medically cautious
- Use the reference content when it is relevant
- State clearly when the answer is not contained in the reference content
- Recommend professional clinical judgment for patient-specific decisions
''';

    return instructions.trim();
  }

  /// Build a compact question payload for the backend chat API.
  String buildContextQuestion(AiContext context, String userQuestion) {
    return '''
Context type: ${context.sourceType.contextInstructions}
Title: ${context.title}
Reference content:
${_formatContextContent(context)}

User question:
${userQuestion.trim()}
'''
        .trim();
  }

  /// Format context content for assistant consumption
  String _formatContextContent(AiContext context) {
    // Clean and truncate content for AI consumption
    String cleanContent = context.content
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    // Truncate if too long (keep within reasonable token limits)
    if (cleanContent.length > 3000) {
      cleanContent =
          '${cleanContent.substring(0, 3000)}... [Content truncated]';
    }

    return cleanContent;
  }

  /// Generate contextual welcome message
  String generateWelcomeMessage(AiContext context) {
    final contextIcon = context.sourceType.icon;
    final contextLabel = context.sourceType.label;

    return '''
$contextIcon **${context.title}**

Hello! I'm your MediGuide AI assistant. I have access to this $contextLabel content and can help answer questions about it.

**I can help you with:**
${_getContextualHelpOptions(context)}

**Ask me anything about this content, or feel free to ask general medical questions!**

*Disclaimer: Always consult with qualified healthcare providers for medical decisions.*
''';
  }

  /// Generate contextual help options based on content type
  String _getContextualHelpOptions(AiContext context) {
    switch (context.sourceType) {
      case AiContextType.guideline:
        return '''
• Explaining treatment protocols and procedures
• Clarifying dosage recommendations
• Understanding contraindications and warnings
• Interpreting clinical decision points
• Related diagnostic criteria''';

      case AiContextType.drug:
        return '''
• Drug mechanisms and pharmacology
• Dosage calculations and timing
• Drug interactions and contraindications
• Side effects and monitoring
• Alternative medications''';

      case AiContextType.calculator:
        return '''
• How to use this calculator
• Interpreting calculation results
• Clinical significance of values
• When to use this tool
• Related assessments''';

      case AiContextType.tool:
        return '''
• Step-by-step tool usage
• Interpreting assessment results
• Clinical applications
• Best practices and tips
• Related diagnostic tools''';

      case AiContextType.consultant:
        return '''
• When to seek consultation
• Preparation for specialist visits
• Understanding specialties
• Referral guidelines
• Follow-up recommendations''';

      case AiContextType.facility:
        return '''
• Available services and departments
• Appointment procedures
• What to expect during visits
• Preparation requirements
• Alternative facilities''';

      case AiContextType.faq:
        return '''
• More detailed explanations
• Related questions and topics
• Practical implementation
• Additional resources
• Follow-up considerations''';

      case AiContextType.genericPage:
      case AiContextType.unknown:
        return '''
• Detailed explanations of content
• Related medical topics
• Practical applications
• Best practices and recommendations
• Additional resources and references''';
    }
  }

  /// Generate contextual example questions
  List<String> generateExampleQuestions(AiContext context) {
    switch (context.sourceType) {
      case AiContextType.guideline:
        return [
          'What are the key steps in this treatment protocol?',
          'When should I consider alternative treatments?',
          'What are the contraindications to be aware of?',
          'How do I monitor treatment progress?',
        ];

      case AiContextType.drug:
        return [
          'What are the main side effects to watch for?',
          'Are there any important drug interactions?',
          'How should this medication be administered?',
          'What monitoring is required?',
        ];

      case AiContextType.calculator:
        return [
          'How do I interpret these results?',
          'What values indicate concern?',
          'When should I use this calculator?',
          'What are the limitations?',
        ];

      case AiContextType.tool:
        return [
          'How do I properly use this tool?',
          'What do these results mean?',
          'When is this assessment most useful?',
          'What are the next steps?',
        ];

      case AiContextType.consultant:
        return [
          'When should I refer to this specialist?',
          'How do I prepare patients for consultation?',
          'What information should I provide?',
          'What are typical wait times?',
        ];

      case AiContextType.facility:
        return [
          'What services are available here?',
          'How do I make an appointment?',
          'What should patients bring?',
          'Are there any special requirements?',
        ];

      case AiContextType.faq:
        return [
          'Can you explain this in more detail?',
          'Are there related considerations?',
          'What are the practical implications?',
          'Where can I find more information?',
        ];

      case AiContextType.genericPage:
      case AiContextType.unknown:
        return [
          'Can you explain this topic in more detail?',
          'What are the key points to remember?',
          'How does this apply in practice?',
          'Are there related topics I should know about?',
        ];
    }
  }

  /// Extract context from different page types
  /// This can be used by pages to easily create context objects

  /// Extract context from guideline data
  AiContext extractGuidelineContext({
    required String conditionName,
    required Map<String, dynamic> guidelineData,
    String? guidelineId,
  }) {
    final content = _buildGuidelineContent(guidelineData);

    return AiContext.guideline(
      title: conditionName,
      content: content,
      guidelineId: guidelineId,
      metadata: {
        'sections': guidelineData.keys.toList(),
        'hasProtocols': guidelineData.containsKey('treatment_protocol'),
        'hasDosages': guidelineData.containsKey('dosages'),
      },
    );
  }

  /// Extract context from generic page data
  AiContext extractGenericPageContext({
    required String title,
    required String content,
    String? description,
    String? pageId,
  }) {
    final fullContent = description != null
        ? '$description\n\n$content'
        : content;

    return AiContext.genericPage(
      title: title,
      content: fullContent,
      pageId: pageId,
      metadata: {
        'hasDescription': description != null,
        'contentLength': fullContent.length,
      },
    );
  }

  /// Build content string from guideline data structure
  String _buildGuidelineContent(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // Add each section content
    data.forEach((key, value) {
      if (value is String && value.isNotEmpty) {
        buffer.writeln('$key:');
        buffer.writeln(value);
        buffer.writeln();
      } else if (value is List && value.isNotEmpty) {
        buffer.writeln('$key:');
        for (final item in value) {
          buffer.writeln('• $item');
        }
        buffer.writeln();
      }
    });

    return buffer.toString().trim();
  }

  /// Clean HTML content for AI consumption
  String cleanHtmlContent(String htmlContent) {
    return htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'&[^;]+;'), ' ') // Remove HTML entities
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }
}
