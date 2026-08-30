part of '../screens/chat_interface_page.dart';

class _ChatAppBarTitle extends StatelessWidget {
  const _ChatAppBarTitle({required this.otherUser});

  final User otherUser;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final displayName = otherUser.name.trim().isNotEmpty
        ? otherUser.name.trim()
        : otherUser.email.trim();

    final subtitle = <String>[
      if (otherUser.jobTitle.trim().isNotEmpty) otherUser.jobTitle.trim(),
      if (otherUser.organization.trim().isNotEmpty)
        otherUser.organization.trim(),
    ].join(' · ');

    return Row(
      children: [
        UserAvatar.small(name: displayName),

        AppSpacing.hGapMd,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle.isNotEmpty ? subtitle : otherUser.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// DATE SEPARATOR
// ===========================================================================
