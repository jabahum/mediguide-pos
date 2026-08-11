import 'package:flutter/material.dart';

const supportedClinicalCallouts = <String>{
  'recommendation',
  'warning',
  'caution',
  'key-point',
  'contraindication',
  'dosage',
  'evidence',
  'definition',
  'procedure',
  'algorithm-reference',
  'clinical-note',
  'referral-criteria',
};

final class ClinicalCalloutData {
  const ClinicalCalloutData({
    required this.type,
    required this.content,
    this.title,
    this.severity,
    this.evidenceGrade,
    this.source,
  });

  final String type;
  final String content;
  final String? title;
  final String? severity;
  final String? evidenceGrade;
  final String? source;
}

sealed class GuidelineContentPart {
  const GuidelineContentPart();
}

final class GuidelineHtmlPart extends GuidelineContentPart {
  const GuidelineHtmlPart(this.content);
  final String content;
}

final class GuidelineCalloutPart extends GuidelineContentPart {
  const GuidelineCalloutPart(this.callout);
  final ClinicalCalloutData callout;
}

List<GuidelineContentPart> parseGuidelineCallouts(String source) {
  final lines = source
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  final parts = <GuidelineContentPart>[];
  final ordinary = <String>[];

  void flushOrdinary() {
    final value = ordinary.join('\n').trim();
    if (value.isNotEmpty) parts.add(GuidelineHtmlPart(value));
    ordinary.clear();
  }

  for (var index = 0; index < lines.length; index++) {
    final opening = RegExp(
      r'^:::([a-z][a-z-]*)(?:\s+(.*))?$',
    ).firstMatch(lines[index].trim());
    if (opening == null ||
        !supportedClinicalCallouts.contains(opening.group(1))) {
      ordinary.add(lines[index]);
      continue;
    }
    final openingLine = lines[index];
    flushOrdinary();
    final metadata = _metadata(opening.group(2) ?? '');
    final body = <String>[];
    index++;
    while (index < lines.length && lines[index].trim() != ':::') {
      body.add(lines[index]);
      index++;
    }
    if (index >= lines.length || body.join('\n').trim().isEmpty) {
      ordinary.addAll([openingLine, ...body]);
      continue;
    }
    parts.add(
      GuidelineCalloutPart(
        ClinicalCalloutData(
          type: opening.group(1)!,
          title: metadata['title'],
          severity: metadata['severity'],
          evidenceGrade: metadata['evidence_grade'],
          source: metadata['source'],
          content: body.join('\n').trim(),
        ),
      ),
    );
  }
  flushOrdinary();
  return parts;
}

Map<String, String> _metadata(String source) {
  final result = <String, String>{};
  final pattern = RegExp(r'''([a-z_]+)=(?:"([^"]*)"|'([^']*)'|([^\s]+))''');
  for (final match in pattern.allMatches(source)) {
    final key = match.group(1)!;
    if (const {'title', 'severity', 'evidence_grade', 'source'}.contains(key)) {
      result[key] = match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
    }
  }
  return result;
}

class ClinicalCalloutCard extends StatelessWidget {
  const ClinicalCalloutCard({super.key, required this.callout});
  final ClinicalCalloutData callout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highRisk = const {
      'warning',
      'caution',
      'contraindication',
      'dosage',
      'referral-criteria',
    }.contains(callout.type);
    final accent = highRisk ? scheme.error : scheme.primary;
    final label = callout.title?.trim().isNotEmpty == true
        ? callout.title!
        : callout.type
              .replaceAll('-', ' ')
              .split(' ')
              .map(
                (part) => part.isEmpty
                    ? part
                    : '${part[0].toUpperCase()}${part.substring(1)}',
              )
              .join(' ');
    return Semantics(
      label: '$label clinical callout',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          border: Border(left: BorderSide(color: accent, width: 4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(callout.content),
            if (callout.severity?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Priority: ${callout.severity}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
            if (callout.evidenceGrade?.isNotEmpty == true)
              Text(
                'Evidence grade: ${callout.evidenceGrade}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            if (callout.source?.isNotEmpty == true)
              Text(
                'Source: ${callout.source}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}
