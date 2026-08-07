import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/shared/models/models.dart';

part 'read_guideline_controller.g.dart';

final class ReadGuidelineRequest {
  const ReadGuidelineRequest({required this.id, this.guideline});

  final String id;
  final Guideline? guideline;

  @override
  bool operator ==(Object other) {
    return other is ReadGuidelineRequest && other.id == id;
  }

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
    bool clearReadingProgress = false,
    String? currentSection,
    double? progressPercentage,
    bool? isBookmarked,
    bool? isMutating,
  }) {
    return ReadGuidelineState(
      guideline: guideline,
      sections: sections,
      readingProgress: clearReadingProgress
          ? null
          : readingProgress ?? this.readingProgress,
      currentSection: currentSection ?? this.currentSection,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

@riverpod
class ReadGuidelineController extends _$ReadGuidelineController {
  @override
  Future<ReadGuidelineState> build(ReadGuidelineRequest request) async {
    final guidelineId = request.id.trim();

    if (guidelineId.isEmpty) {
      throw ArgumentError.value(request.id, 'guidelineId', 'is required');
    }

    final guideline =
        request.guideline ??
        await ref
            .read(guidelineContentRepositoryProvider)
            .guideline(guidelineId);

    final sections = List<GuidelineSection>.unmodifiable(
      guidelineSections(guideline),
    );

    unawaited(_trackUsage(guideline.id));

    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (user == null) {
      return ReadGuidelineState(guideline: guideline, sections: sections);
    }

    try {
      final repository = ref.read(readingProgressRepositoryProvider);

      var progress = await repository.forGuideline(user.id, guideline.id);

      progress ??= await repository.upsert(user.id, guideline.id, {
        'current_section': 'definition',
        'total_sections': sections.length,
        'progress_percentage': 0.0,
        'last_read_at': DateTime.now().toUtc().toIso8601String(),
      });

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
      // A guideline must remain readable even when reading
      // progress cannot be loaded.
      return ReadGuidelineState(guideline: guideline, sections: sections);
    }
  }

  // ======================================================
  // SECTION
  // ======================================================

  void selectSection(GuidelineSection section) {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(currentSection: section.fieldName));
  }

  // ======================================================
  // PROGRESS
  // ======================================================

  void setProgress(double progress) {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(progressPercentage: progress.clamp(0.0, 1.0)),
    );
  }

  Future<void> saveProgress() async {
    final current = state.valueOrNull;

    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (current == null || user == null) {
      return;
    }

    final completed = current.progressPercentage >= 0.95;

    try {
      final record = await ref
          .read(readingProgressRepositoryProvider)
          .upsert(user.id, current.guideline.id, {
            'current_section': current.currentSection,
            'progress_percentage': current.progressPercentage,
            'last_read_at': DateTime.now().toUtc().toIso8601String(),
            'is_completed': completed,
          });

      if (!ref.mounted) {
        return;
      }

      final latest = state.valueOrNull;

      if (latest == null) {
        return;
      }

      state = AsyncData(latest.copyWith(readingProgress: record));
    } catch (_) {
      // Saving reading progress is best effort.
      // It should never interrupt guideline reading.
    }
  }

  // ======================================================
  // BOOKMARK
  // ======================================================

  Future<bool> toggleBookmark() async {
    final current = state.valueOrNull;

    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (current == null || user == null || current.isMutating) {
      return false;
    }

    final next = !current.isBookmarked;

    state = AsyncData(current.copyWith(isMutating: true));

    try {
      final record = await ref.read(readingProgressRepositoryProvider).upsert(
        user.id,
        current.guideline.id,
        {'is_bookmarked': next},
      );

      if (!ref.mounted) {
        return false;
      }

      final latest = state.valueOrNull;

      if (latest == null) {
        return false;
      }

      state = AsyncData(
        latest.copyWith(
          readingProgress: record,
          isBookmarked: next,
          isMutating: false,
        ),
      );

      return true;
    } catch (_) {
      if (ref.mounted) {
        final latest = state.valueOrNull;

        if (latest != null) {
          state = AsyncData(latest.copyWith(isMutating: false));
        }
      }

      return false;
    }
  }

  // ======================================================
  // COMPLETE
  // ======================================================

  Future<bool> markCompleted() async {
    final current = state.valueOrNull;

    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (current == null || user == null || current.isMutating) {
      return false;
    }

    state = AsyncData(current.copyWith(isMutating: true));

    try {
      final record = await ref
          .read(readingProgressRepositoryProvider)
          .upsert(user.id, current.guideline.id, {
            'progress_percentage': 1.0,
            'is_completed': true,
            'last_read_at': DateTime.now().toUtc().toIso8601String(),
          });

      if (!ref.mounted) {
        return false;
      }

      final latest = state.valueOrNull;

      if (latest == null) {
        return false;
      }

      state = AsyncData(
        latest.copyWith(
          readingProgress: record,
          progressPercentage: 1.0,
          isMutating: false,
        ),
      );

      return true;
    } catch (_) {
      if (ref.mounted) {
        final latest = state.valueOrNull;

        if (latest != null) {
          state = AsyncData(latest.copyWith(isMutating: false));
        }
      }

      return false;
    }
  }

  // ======================================================
  // REFRESH
  // ======================================================

  Future<void> reload() async {
    ref.invalidateSelf();

    await future;
  }

  // ======================================================
  // USAGE
  // ======================================================

  Future<void> _trackUsage(String guidelineId) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (user == null) {
      return;
    }

    try {
      await ref.read(usageRepositoryProvider).guideline(guidelineId);
    } catch (_) {
      // Analytics must never block guideline reading.
    }
  }
}

// ======================================================
// SECTIONS
// ======================================================

List<GuidelineSection> guidelineSections(Guideline guideline) {
  return [
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

    if (guideline.monitoringRequirements.isNotEmpty)
      GuidelineSection.monitoring,

    if (guideline.preventionMeasures.isNotEmpty) GuidelineSection.prevention,

    if (guideline.specialNotes.isNotEmpty) GuidelineSection.specialNotes,
  ];
}

String guidelineSectionContent(Guideline guideline, GuidelineSection section) {
  return switch (section) {
    GuidelineSection.definition => guideline.definition,

    GuidelineSection.causes => guideline.causes,

    GuidelineSection.clinicalFeatures => guideline.clinicalFeatures,

    GuidelineSection.differentialDiagnosis => guideline.differentialDiagnosis,

    GuidelineSection.classification => _classificationContent(guideline),

    GuidelineSection.generalManagement => guideline.generalManagement,

    GuidelineSection.medication => _medicationContent(guideline),

    GuidelineSection.monitoring => guideline.monitoringRequirements,

    GuidelineSection.prevention => guideline.preventionMeasures,

    GuidelineSection.specialNotes => guideline.specialNotes,
  };
}

String _classificationContent(Guideline guideline) {
  final content = StringBuffer();

  final classifications = <String, String>{
    'Mild': guideline.classificationMild,
    'Moderate': guideline.classificationModerate,
    'Severe': guideline.classificationSevere,
    'Critical': guideline.classificationCritical,
  };

  for (final entry in classifications.entries) {
    if (entry.value.isEmpty) {
      continue;
    }

    content
      ..writeln('<h4>${entry.key}</h4>')
      ..writeln(entry.value);
  }

  return content.toString();
}

String _medicationContent(Guideline guideline) {
  final content = StringBuffer();

  void appendSection(String heading, String value, {int level = 4}) {
    if (value.isEmpty) {
      return;
    }

    content
      ..writeln('<h$level>$heading</h$level>')
      ..writeln(value);
  }

  appendSection('Primary Medication', guideline.medicationPrimary);

  appendSection('Adult Dosage', guideline.dosageAdult, level: 5);

  appendSection('Pediatric Dosage', guideline.dosagePediatric, level: 5);

  appendSection('Secondary Medication', guideline.medicationSecondary);

  appendSection('Adult Dosage', guideline.dosageSecondaryAdult, level: 5);

  appendSection(
    'Pediatric Dosage',
    guideline.dosageSecondaryPediatric,
    level: 5,
  );

  appendSection('Route of Administration', guideline.routeAdministration);

  appendSection('Contraindications', guideline.contraindications);

  return content.toString();
}
