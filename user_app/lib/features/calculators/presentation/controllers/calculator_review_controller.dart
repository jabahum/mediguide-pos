import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_review_repository.dart';

final calculatorReviewControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CalculatorReviewController, CalculatorReviewPreview, String>(
      CalculatorReviewController.new,
    );

class CalculatorReviewController
    extends AutoDisposeFamilyAsyncNotifier<CalculatorReviewPreview, String> {
  @override
  Future<CalculatorReviewPreview> build(String versionId) {
    return ref.watch(calculatorReviewRepositoryProvider).preview(versionId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(calculatorReviewRepositoryProvider).preview(arg),
    );
  }

  Future<void> addComment(String comment) async {
    await ref.read(calculatorReviewRepositoryProvider).addComment(arg, comment);
    await refresh();
  }
}
