import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/repositories/progress_usage_repository.dart';
import '../../utils/common.dart';

class ReadGuidelineController extends GetxController {
  ReadingProgressRepository get _progressRepository =>
      ReadingProgressRepository(BackendApiService.to);
  UsageRepository get _usageRepository => UsageRepository(BackendApiService.to);
  // Observable state
  final Rx<Guideline?> guideline = Rx<Guideline?>(null);
  final Rx<ReadingProgress?> readingProgress = Rx<ReadingProgress?>(null);
  final RxString currentSection = 'definition'.obs;
  final RxDouble progressPercentage = 0.0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isBookmarked = false.obs;
  final RxList<GuidelineSection> availableSections = <GuidelineSection>[].obs;

  // Scroll controller for tracking reading progress
  final ScrollController scrollController = ScrollController();

  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Guideline) {
      guideline.value = args;
      _determineAvailableSections();
      _loadReadingProgress();
      _trackGuidelineUsage(args.id);
    }
    _setupScrollListener();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;

      if (maxScroll > 0) {
        final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
        progressPercentage.value = progress;
        _saveProgressDebounced();
      }
    });
  }

  void _determineAvailableSections() {
    if (guideline.value == null) return;

    final sections = <GuidelineSection>[];
    final g = guideline.value!;

    if (g.hasDefinition) {
      sections.add(GuidelineSection.definition);
    }
    if (g.hasCauses) {
      sections.add(GuidelineSection.causes);
    }
    if (g.hasClinicalFeatures) {
      sections.add(GuidelineSection.clinicalFeatures);
    }
    if (g.differentialDiagnosis.isNotEmpty) {
      sections.add(GuidelineSection.differentialDiagnosis);
    }
    if (g.hasClassifications) {
      sections.add(GuidelineSection.classification);
    }
    if (g.generalManagement.isNotEmpty) {
      sections.add(GuidelineSection.generalManagement);
    }
    if (g.hasPrimaryMedication || g.hasSecondaryMedication) {
      sections.add(GuidelineSection.medication);
    }
    if (g.monitoringRequirements.isNotEmpty) {
      sections.add(GuidelineSection.monitoring);
    }
    if (g.preventionMeasures.isNotEmpty) {
      sections.add(GuidelineSection.prevention);
    }
    if (g.specialNotes.isNotEmpty) {
      sections.add(GuidelineSection.specialNotes);
    }

    availableSections.assignAll(sections);
  }

  Future<void> _loadReadingProgress() async {
    if (guideline.value == null || AuthService.to.currentUser.value == null) {
      return;
    }

    try {
      final userId = AuthService.to.currentUser.value!.id;
      final guidelineId = guideline.value!.id;

      final record = await _progressRepository.forGuideline(
        userId,
        guidelineId,
      );

      if (record != null) {
        readingProgress.value = ReadingProgress.fromRecord(record);
        currentSection.value = readingProgress.value!.currentSection;
        progressPercentage.value = readingProgress.value!.progressPercentage;
        isBookmarked.value = readingProgress.value!.isBookmarked;
      } else {
        await _createInitialProgress();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _createInitialProgress() async {
    if (guideline.value == null || AuthService.to.currentUser.value == null) {
      return;
    }

    try {
      final userId = AuthService.to.currentUser.value!.id;
      final guidelineId = guideline.value!.id;

      final progressData = ReadingProgress.forCreate(
        userId: userId,
        guidelineId: guidelineId,
        currentSection: 'definition',
        totalSections: availableSections.length,
        progressPercentage: 0.0,
      );

      final record = await _progressRepository.upsert(
        userId,
        guidelineId,
        progressData,
      );

      readingProgress.value = ReadingProgress.fromRecord(record);
    } catch (e) {
      // Handle error silently
    }
  }

  void _saveProgressDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  Future<void> _saveProgress() async {
    if (readingProgress.value == null) return;

    try {
      final isCompleted = progressPercentage.value >= 0.95;

      await _progressRepository
          .upsert(AuthService.to.currentUser.value!.id, guideline.value!.id, {
            'current_section': currentSection.value,
            'progress_percentage': progressPercentage.value,
            'last_read_at': DateTime.now().toIso8601String(),
            'is_completed': isCompleted,
          });

      final updatedData = Map<String, dynamic>.from(
        readingProgress.value!.data,
      );
      updatedData.addAll({
        'current_section': currentSection.value,
        'progress_percentage': progressPercentage.value,
        'last_read_at': DateTime.now().toIso8601String(),
        'is_completed': isCompleted,
      });

      readingProgress.value = ReadingProgress(updatedData);
    } catch (e) {
      // Handle error silently
    }
  }

  final Map<String, GlobalKey> sectionKeys = {};

  void navigateToSection(GuidelineSection section) {
    currentSection.value = section.fieldName;

    // Scroll to section if key exists
    final key = sectionKeys[section.fieldName];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  GlobalKey getSectionKey(GuidelineSection section) {
    final keyName = section.fieldName;
    if (!sectionKeys.containsKey(keyName)) {
      sectionKeys[keyName] = GlobalKey();
    }
    return sectionKeys[keyName]!;
  }

  Future<void> toggleBookmark() async {
    if (readingProgress.value == null) return;

    try {
      isLoading.value = true;
      final newBookmarkStatus = !isBookmarked.value;

      await _progressRepository.upsert(
        AuthService.to.currentUser.value!.id,
        guideline.value!.id,
        {'is_bookmarked': newBookmarkStatus},
      );

      isBookmarked.value = newBookmarkStatus;

      Common.quickToast(
        title: newBookmarkStatus ? 'Guideline bookmarked' : 'Bookmark removed',
      );
    } catch (e) {
      Common.quickToast(
        title: 'Failed to update bookmark',
        type: ToastificationType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsCompleted() async {
    if (readingProgress.value == null) return;

    try {
      isLoading.value = true;

      await _progressRepository
          .upsert(AuthService.to.currentUser.value!.id, guideline.value!.id, {
            'progress_percentage': 1.0,
            'is_completed': true,
            'last_read_at': DateTime.now().toIso8601String(),
          });

      progressPercentage.value = 1.0;

      Common.quickToast(title: 'Guideline marked as completed!');
    } catch (e) {
      Common.quickToast(
        title: 'Failed to mark as completed',
        type: ToastificationType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String getSectionContent(GuidelineSection section) {
    if (guideline.value == null) return '';

    final g = guideline.value!;
    switch (section) {
      case GuidelineSection.definition:
        return g.definition;
      case GuidelineSection.causes:
        return g.causes;
      case GuidelineSection.clinicalFeatures:
        return g.clinicalFeatures;
      case GuidelineSection.differentialDiagnosis:
        return g.differentialDiagnosis;
      case GuidelineSection.classification:
        return _buildClassificationContent();
      case GuidelineSection.generalManagement:
        return g.generalManagement;
      case GuidelineSection.medication:
        return _buildMedicationContent();
      case GuidelineSection.monitoring:
        return g.monitoringRequirements;
      case GuidelineSection.prevention:
        return g.preventionMeasures;
      case GuidelineSection.specialNotes:
        return g.specialNotes;
    }
  }

  String _buildClassificationContent() {
    if (guideline.value == null) return '';

    final g = guideline.value!;
    final content = StringBuffer();

    if (g.classificationMild.isNotEmpty) {
      content.writeln('<h4>Mild</h4>');
      content.writeln(g.classificationMild);
      content.writeln();
    }

    if (g.classificationModerate.isNotEmpty) {
      content.writeln('<h4>Moderate</h4>');
      content.writeln(g.classificationModerate);
      content.writeln();
    }

    if (g.classificationSevere.isNotEmpty) {
      content.writeln('<h4>Severe</h4>');
      content.writeln(g.classificationSevere);
      content.writeln();
    }

    if (g.classificationCritical.isNotEmpty) {
      content.writeln('<h4>Critical</h4>');
      content.writeln(g.classificationCritical);
    }

    return content.toString();
  }

  String _buildMedicationContent() {
    if (guideline.value == null) return '';

    final g = guideline.value!;
    final content = StringBuffer();

    if (g.medicationPrimary.isNotEmpty) {
      content.writeln('<h4>Primary Medication</h4>');
      content.writeln(g.medicationPrimary);

      if (g.dosageAdult.isNotEmpty) {
        content.writeln('<h5>Adult Dosage</h5>');
        content.writeln(g.dosageAdult);
      }

      if (g.dosagePediatric.isNotEmpty) {
        content.writeln('<h5>Pediatric Dosage</h5>');
        content.writeln(g.dosagePediatric);
      }
      content.writeln();
    }

    if (g.medicationSecondary.isNotEmpty) {
      content.writeln('<h4>Secondary Medication</h4>');
      content.writeln(g.medicationSecondary);

      if (g.dosageSecondaryAdult.isNotEmpty) {
        content.writeln('<h5>Adult Dosage</h5>');
        content.writeln(g.dosageSecondaryAdult);
      }

      if (g.dosageSecondaryPediatric.isNotEmpty) {
        content.writeln('<h5>Pediatric Dosage</h5>');
        content.writeln(g.dosageSecondaryPediatric);
      }
    }

    if (g.routeAdministration.isNotEmpty) {
      content.writeln('<h4>Route of Administration</h4>');
      content.writeln(g.routeAdministration);
    }

    if (g.contraindications.isNotEmpty) {
      content.writeln('<h4>Contraindications</h4>');
      content.writeln(g.contraindications);
    }

    return content.toString();
  }

  /// Track guideline usage
  Future<void> _trackGuidelineUsage(String guidelineId) async {
    try {
      if (AuthService.to.currentUser.value == null) return;

      // Create guideline usage log
      await _usageRepository.guideline(guidelineId);
    } catch (e) {
      // Handle error silently to not disrupt user experience
    }
  }
}
