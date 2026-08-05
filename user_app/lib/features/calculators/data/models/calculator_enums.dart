/// Calculator type enum - defines the type of calculator/tool
enum CalculatorType {
  calculator(label: 'Calculator'),
  decisionTool(label: 'Decision Tool'),
  checklist(label: 'Checklist');

  const CalculatorType({required this.label});

  final String label;
}

/// Calculator status enum - defines the current status of the calculator
enum CalculatorStatus {
  active(label: 'Active'),
  draft(label: 'Draft'),
  archived(label: 'Archived');

  const CalculatorStatus({required this.label});

  final String label;
}
