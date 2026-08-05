import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authControllerProvider).valueOrNull?.user;
});
