import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/data/models/reading_progress.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';

part 'publication_guideline_controller.g.dart';

@riverpod
Future<GuidelinePublicationContent> publicationGuideline(
  PublicationGuidelineRef ref,
  String guidelineId,
) => ref.watch(guidelinePublicationRepositoryProvider).content(guidelineId);

@riverpod
Future<GuidelineAsset?> guidelineOriginalDocument(
  GuidelineOriginalDocumentRef ref,
  String guidelineId,
) => ref
    .watch(guidelinePublicationRepositoryProvider)
    .originalDocument(guidelineId);

@riverpod
Future<GuidelineAsset?> guidelineOfflinePackage(
  GuidelineOfflinePackageRef ref,
  String guidelineId,
) => ref
    .watch(guidelinePublicationRepositoryProvider)
    .offlinePackage(guidelineId);

@riverpod
Future<ReadingProgress?> publicationReadingProgress(
  PublicationReadingProgressRef ref,
  String guidelineId,
) {
  final user = ref.watch(authControllerProvider).valueOrNull?.user;
  if (user == null) return Future<ReadingProgress?>.value();
  return ref
      .watch(readingProgressRepositoryProvider)
      .forGuideline(user.id, guidelineId);
}
