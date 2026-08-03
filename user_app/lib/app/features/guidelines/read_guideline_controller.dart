import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/core_providers.dart';
import '../auth/auth_controller.dart';

final class ReadGuidelineRequest {
  const ReadGuidelineRequest({required this.id, this.guideline});

  final String id;
  final Guideline? guideline;

  @override
  bool operator ==(Object other) =>
      other is ReadGuidelineRequest && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final class ReadGuidelineState {
  const ReadGuidelineState({
    required this.guideline,
    required this.sections,
    this.readingProgress,
    this.currentSection = 'definition',
    this.progressPercentage = 0,
    this.isBookmarked = false,
    this.isMutating = false,
  });

  final Guideline guideline;
  final List<GuidelineSection> sections;
  final ReadingProgress? readingProgress;
  final String currentSection;
  final double progressPercentage;
  final bool isBookmarked;
  final bool isMutating;

  ReadGuidelineState copyWith({
    ReadingProgress? readingProgress,
    String? currentSection,
    double? progressPercentage,
    bool? isBookmarked,
    bool? isMutating,
  }) => ReadGuidelineState(
    guideline: guideline,
    sections: sections,
    readingProgress: readingProgress ?? this.readingProgress,
    currentSection: currentSection ?? this.currentSection,
    progressPercentage: progressPercentage ?? this.progressPercentage,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    isMutating: isMutating ?? this.isMutating,
  );
}

final readGuidelineControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      ReadGuidelineController,
      ReadGuidelineState,
      ReadGuidelineRequest
    >(ReadGuidelineController.new);

class ReadGuidelineController
    extends
        AutoDisposeFamilyAsyncNotifier<
          ReadGuidelineState,
          ReadGuidelineRequest
        > {
  bool _disposed = false;

  @override
  Future<ReadGuidelineState> build(ReadGuidelineRequest request) async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    if (request.id.isEmpty) {
      throw ArgumentError.value(request.id, 'guidelineId', 'is required');
    }
    final guideline =
        request.guideline ??
        Guideline.fromRecord(
          await ref
              .read(guidelineContentRepositoryProvider)
              .guideline(request.id),
        );
    final sections = guidelineSections(guideline);
    unawaited(_trackUsage(guideline.id));

    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) {
      return ReadGuidelineState(guideline: guideline, sections: sections);
    }

    try {
      var record = await ref
          .read(readingProgressRepositoryProvider)
          .forGuideline(user.id, guideline.id);
      record ??= await ref
          .read(readingProgressRepositoryProvider)
          .upsert(
            user.id,
            guideline.id,
            ReadingProgress.forCreate(
              userId: user.id,
              guidelineId: guideline.id,
              currentSection: 'definition',
              totalSections: sections.length,
              progressPercentage: 0,
            ),
          );
      final progress = ReadingProgress.fromRecord(record);
      return ReadGuidelineState(
        guideline: guideline,
        sections: sections,
        readingProgress: progress,
        currentSection: progress.currentSection.isEmpty
            ? 'definition'
            : progress.currentSection,
        progressPercentage: progress.progressPercentage,
        isBookmarked: progress.isBookmarked,
      );
    } catch (_) {
      return ReadGuidelineState(guideline: guideline, sections: sections);
    }
  }

  void selectSection(GuidelineSection section) {
    final value = state.valueOrNull;
    if (value == null) return;
    state = AsyncData(value.copyWith(currentSection: section.fieldName));
  }

  void setProgress(double progress) {
    final value = state.valueOrNull;
    if (value == null) return;
    state = AsyncData(
      value.copyWith(progressPercentage: progress.clamp(0.0, 1.0)),
    );
  }

  Future<void> saveProgress() async {
    final value = state.valueOrNull;
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (value == null || user == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final completed = value.progressPercentage >= 0.95;
    final record = await ref
        .read(readingProgressRepositoryProvider)
        .upsert(user.id, value.guideline.id, {
          'current_section': value.currentSection,
          'progress_percentage': value.progressPercentage,
          'last_read_at': now,
          'is_completed': completed,
        });
    if (_disposed) return;
    state = AsyncData(
      value.copyWith(readingProgress: ReadingProgress.fromRecord(record)),
    );
  }

  Future<bool> toggleBookmark() async {
    final value = state.valueOrNull;
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (value == null || user == null || value.isMutating) return false;
    final next = !value.isBookmarked;
    state = AsyncData(value.copyWith(isMutating: true));
    try {
      final record = await ref.read(readingProgressRepositoryProvider).upsert(
        user.id,
        value.guideline.id,
        {'is_bookmarked': next},
      );
      if (_disposed) return false;
      state = AsyncData(
        value.copyWith(
          readingProgress: ReadingProgress.fromRecord(record),
          isBookmarked: next,
          isMutating: false,
        ),
      );
      return true;
    } catch (_) {
      if (!_disposed) state = AsyncData(value.copyWith(isMutating: false));
      return false;
    }
  }

  Future<bool> markCompleted() async {
    final value = state.valueOrNull;
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (value == null || user == null || value.isMutating) return false;
    state = AsyncData(value.copyWith(isMutating: true));
    try {
      final record = await ref
          .read(readingProgressRepositoryProvider)
          .upsert(user.id, value.guideline.id, {
            'progress_percentage': 1.0,
            'is_completed': true,
            'last_read_at': DateTime.now().toUtc().toIso8601String(),
          });
      if (_disposed) return false;
      state = AsyncData(
        value.copyWith(
          readingProgress: ReadingProgress.fromRecord(record),
          progressPercentage: 1,
          isMutating: false,
        ),
      );
      return true;
    } catch (_) {
      if (!_disposed) state = AsyncData(value.copyWith(isMutating: false));
      return false;
    }
  }

  Future<void> _trackUsage(String id) async {
    if (ref.read(authControllerProvider).valueOrNull?.user == null) return;
    try {
      await ref.read(usageRepositoryProvider).guideline(id);
    } catch (_) {
      // Analytics must not block guideline reading.
    }
  }
}

List<GuidelineSection> guidelineSections(Guideline guideline) => [
  if (guideline.hasDefinition) GuidelineSection.definition,
  if (guideline.hasCauses) GuidelineSection.causes,
  if (guideline.hasClinicalFeatures) GuidelineSection.clinicalFeatures,
  if (guideline.differentialDiagnosis.isNotEmpty)
    GuidelineSection.differentialDiagnosis,
  if (guideline.hasClassifications) GuidelineSection.classification,
  if (guideline.generalManagement.isNotEmpty)
    GuidelineSection.generalManagement,
  if (guideline.hasPrimaryMedication || guideline.hasSecondaryMedication)
    GuidelineSection.medication,
  if (guideline.monitoringRequirements.isNotEmpty) GuidelineSection.monitoring,
  if (guideline.preventionMeasures.isNotEmpty) GuidelineSection.prevention,
  if (guideline.specialNotes.isNotEmpty) GuidelineSection.specialNotes,
];

String guidelineSectionContent(Guideline guideline, GuidelineSection section) {
  switch (section) {
    case GuidelineSection.definition:
      return guideline.definition;
    case GuidelineSection.causes:
      return guideline.causes;
    case GuidelineSection.clinicalFeatures:
      return guideline.clinicalFeatures;
    case GuidelineSection.differentialDiagnosis:
      return guideline.differentialDiagnosis;
    case GuidelineSection.classification:
      return _classificationContent(guideline);
    case GuidelineSection.generalManagement:
      return guideline.generalManagement;
    case GuidelineSection.medication:
      return _medicationContent(guideline);
    case GuidelineSection.monitoring:
      return guideline.monitoringRequirements;
    case GuidelineSection.prevention:
      return guideline.preventionMeasures;
    case GuidelineSection.specialNotes:
      return guideline.specialNotes;
  }
}

String _classificationContent(Guideline guideline) {
  final content = StringBuffer();
  for (final entry in {
    'Mild': guideline.classificationMild,
    'Moderate': guideline.classificationModerate,
    'Severe': guideline.classificationSevere,
    'Critical': guideline.classificationCritical,
  }.entries) {
    if (entry.value.isNotEmpty) {
      content
        ..writeln('<h4>${entry.key}</h4>')
        ..writeln(entry.value);
    }
  }
  return content.toString();
}

String _medicationContent(Guideline guideline) {
  final content = StringBuffer();
  void section(String heading, String value, {int level = 4}) {
    if (value.isNotEmpty) {
      content
        ..writeln('<h$level>$heading</h$level>')
        ..writeln(value);
    }
  }

  section('Primary Medication', guideline.medicationPrimary);
  section('Adult Dosage', guideline.dosageAdult, level: 5);
  section('Pediatric Dosage', guideline.dosagePediatric, level: 5);
  section('Secondary Medication', guideline.medicationSecondary);
  section('Adult Dosage', guideline.dosageSecondaryAdult, level: 5);
  section('Pediatric Dosage', guideline.dosageSecondaryPediatric, level: 5);
  section('Route of Administration', guideline.routeAdministration);
  section('Contraindications', guideline.contraindications);
  return content.toString();
}
