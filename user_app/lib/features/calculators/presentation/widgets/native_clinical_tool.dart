import 'package:flutter/material.dart';
import 'package:user_app/features/calculators/data/models/clinical_tool_definition.dart';
import 'package:user_app/features/calculators/domain/clinical_tool_evaluator.dart';

class NativeClinicalTool extends StatefulWidget {
  const NativeClinicalTool({
    super.key,
    required this.definition,
    this.initialValues = const {},
    this.onChanged,
  });
  final ClinicalToolDefinition definition;
  final Map<String, Object?> initialValues;
  final ValueChanged<Map<String, Object?>>? onChanged;
  @override
  State<NativeClinicalTool> createState() => _NativeClinicalToolState();
}

class _NativeClinicalToolState extends State<NativeClinicalTool> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, Object?> _values = {};
  final Map<String, String> _units = {};
  ClinicalToolResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _values.addAll(widget.initialValues);
    for (final input in widget.definition.inputs) {
      final restored = widget.initialValues[input.key];
      _units[input.key] = restored is Map
          ? restored['unit']?.toString() ?? input.defaultUnit
          : input.defaultUnit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            definition.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (definition.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(definition.description),
          ],
          const SizedBox(height: 16),
          ...definition.warnings
              .where((item) => item.when == null)
              .map((item) => _MessageCard(message: item)),
          ...definition.inputs.map(_input),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: Text(
              definition.toolType == 'checklist'
                  ? 'Review checklist'
                  : 'Calculate',
            ),
          ),
          TextButton(onPressed: _reset, child: const Text('Reset')),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_result != null)
            _ResultView(definition: definition, result: _result!),
          if (definition.citations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Clinical sources',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...definition.citations.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(item.title),
                subtitle: Text(item.organization),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _input(ClinicalToolInput input) {
    if (input.type == 'boolean' || input.type == 'checklist_item') {
      return Semantics(
        label: input.label,
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(input.label),
          subtitle: input.clinicalWarning.isEmpty
              ? null
              : Text(input.clinicalWarning),
          value: _values[input.key] == true,
          onChanged: (value) {
            setState(() => _values[input.key] = value ?? false);
            _changed();
          },
        ),
      );
    }
    if (input.options.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<Object?>(
          initialValue: _values[input.key],
          decoration: InputDecoration(
            labelText: input.label,
            helperText: input.helpText.isEmpty ? null : input.helpText,
          ),
          items: input.options
              .map(
                (option) => DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            _values[input.key] = value;
            _changed();
          },
          validator: (value) => input.required && value == null
              ? '${input.label} is required'
              : null,
        ),
      );
    }
    final textField = TextFormField(
      initialValue: _displayValue(_values[input.key]),
      decoration: InputDecoration(
        labelText: input.label,
        helperText: input.helpText.isEmpty ? input.defaultUnit : input.helpText,
      ),
      keyboardType: input.type == 'number'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: (value) =>
          input.required && (value == null || value.trim().isEmpty)
          ? '${input.label} is required'
          : null,
      onChanged: (value) {
        final parsed = input.type == 'number' ? double.tryParse(value) : value;
        _values[input.key] = input.allowedUnits.isEmpty
            ? parsed
            : {'value': parsed, 'unit': _units[input.key]};
        _changed();
      },
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: input.allowedUnits.isEmpty
          ? textField
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: textField),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    initialValue: _units[input.key],
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: input.allowedUnits
                        .map(
                          (unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)),
                        )
                        .toList(),
                    onChanged: (unit) {
                      if (unit == null) return;
                      _units[input.key] = unit;
                      final current = _values[input.key];
                      final raw = current is Map ? current['value'] : current;
                      _values[input.key] = {'value': raw, 'unit': unit};
                      _changed();
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String? _displayValue(Object? value) =>
      value is Map ? value['value']?.toString() : value?.toString();

  void _calculate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final value = const ClinicalToolEvaluator().evaluate(
        widget.definition,
        _values,
      );
      setState(() {
        _result = value;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _result = null;
        _error = error.toString();
      });
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    setState(() {
      _values.clear();
      _result = null;
      _error = null;
    });
    _changed();
  }

  void _changed() => widget.onChanged?.call(Map<String, Object?>.from(_values));
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final ClinicalToolMessage message;
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(message.text)),
        ],
      ),
    ),
  );
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.definition, required this.result});
  final ClinicalToolDefinition definition;
  final ClinicalToolResult result;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Result', style: Theme.of(context).textTheme.titleLarge),
            ...definition.outputs.map(
              (output) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${output.label}: ${result.values[output.key] ?? '—'} ${output.unit}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (result.interpretation != null) ...[
              const Divider(),
              Text(
                result.interpretation!.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (result.interpretation!.description.isNotEmpty)
                Text(result.interpretation!.description),
            ],
            ...result.recommendations.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(item),
              ),
            ),
            ...result.warnings.map((item) => _MessageCard(message: item)),
          ],
        ),
      ),
    ),
  );
}
