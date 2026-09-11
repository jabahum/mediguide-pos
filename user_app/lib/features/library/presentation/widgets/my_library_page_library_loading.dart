part of '../screens/my_library_page.dart';

class _LibraryLoading extends StatelessWidget {
  const _LibraryLoading();

  @override
  Widget build(BuildContext context) {
    return const AppLoadingView(message: 'Loading your library...');
  }
}
