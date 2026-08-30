part of '../screens/edit_profile_page.dart';

class _ProfilePhotoSection extends StatelessWidget {
  const _ProfilePhotoSection({
    required this.name,
    required this.avatarUrl,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Semantics(
            button: true,
            label: 'Change profile photo',
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar.xlarge(
                    name: name,
                    avatarUrl: avatarUrl,
                    showEditButton: false,
                    isLoading: false,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 3),
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 16,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapSm,
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(LucideIcons.camera, size: 16),
            label: const Text('Change photo'),
          ),
        ],
      ),
    );
  }
}
