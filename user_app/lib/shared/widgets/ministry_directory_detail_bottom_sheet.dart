import 'package:flutter/material.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/features/content/data/models/ministry_directory.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/shared/widgets/section_group.dart';

/// Clean bottom sheet for ministry directory contact details.
class MinistryDirectoryDetailBottomSheet extends StatelessWidget {
  final MinistryDirectory entry;

  const MinistryDirectoryDetailBottomSheet({super.key, required this.entry});

  static void show(BuildContext context, MinistryDirectory entry) {
    AppNavigator.bottomSheet(
      MinistryDirectoryDetailBottomSheet(entry: entry),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  if (entry.isEmergencyContact) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'EMERGENCY',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.onError,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    AppSpacing.gapSm,
                  ],
                  Text(
                    entry.name,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.ministry.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  AppSpacing.gapLg,

                  // ── Contact actions ──
                  SectionGroup(
                    title: 'Contact',
                    items: [
                      _ContactRow(
                        icon: LucideIcons.phone,
                        label: 'Phone',
                        value: entry.phone,
                        onTap: () => Common.makeCall(
                          entry.phone,
                          contactName: entry.name,
                        ),
                      ),
                      if (entry.alternativePhone.isNotEmpty)
                        _ContactRow(
                          icon: LucideIcons.phoneCall,
                          label: 'Alt. Phone',
                          value: entry.alternativePhone,
                          onTap: () => Common.makeCall(
                            entry.alternativePhone,
                            contactName: entry.name,
                          ),
                        ),
                      if (entry.email.isNotEmpty)
                        _ContactRow(
                          icon: LucideIcons.mail,
                          label: 'Email',
                          value: entry.email,
                          onTap: () => Common.sendEmail(
                            entry.email,
                            subject: 'Ministry Directory Inquiry',
                            contactName: entry.name,
                          ),
                        ),
                    ],
                  ),

                  // ── Details ──
                  if (entry.department.isNotEmpty ||
                      entry.locationString.isNotEmpty ||
                      entry.officeAddress.isNotEmpty ||
                      entry.availabilityHours.isNotEmpty ||
                      entry.specialization.isNotEmpty ||
                      entry.notes.isNotEmpty) ...[
                    AppSpacing.gapMd,
                    SectionGroup(
                      title: 'Details',
                      items: [
                        if (entry.department.isNotEmpty)
                          _DetailRow(
                            icon: LucideIcons.briefcase,
                            label: 'Department',
                            value: entry.department,
                          ),
                        if (entry.locationString.isNotEmpty)
                          _DetailRow(
                            icon: LucideIcons.mapPin,
                            label: 'Location',
                            value: entry.locationString,
                          ),
                        if (entry.officeAddress.isNotEmpty)
                          _DetailRow(
                            icon: LucideIcons.building,
                            label: 'Office',
                            value: entry.officeAddress,
                          ),
                        if (entry.availabilityHours.isNotEmpty)
                          _DetailRow(
                            icon: LucideIcons.clock,
                            label: 'Hours',
                            value: entry.availabilityHours,
                          ),
                        if (entry.specialization.isNotEmpty)
                          _DetailRow(
                            icon: LucideIcons.award,
                            label: 'Specialization',
                            value: entry.specialization,
                          ),
                        if (entry.notes.isNotEmpty)
                          _DetailRow(
                            icon: LucideIcons.fileText,
                            label: 'Notes',
                            value: entry.notes,
                          ),
                      ],
                    ),
                  ],

                  // ── Action buttons ──
                  AppSpacing.gapLg,
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Common.makeCall(
                            entry.phone,
                            contactName: entry.name,
                          ),
                          icon: const Icon(LucideIcons.phone, size: 18),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                      if (entry.email.isNotEmpty) ...[
                        AppSpacing.hGapMd,
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Common.sendEmail(
                              entry.email,
                              subject: 'Ministry Directory Inquiry',
                              contactName: entry.name,
                            ),
                            icon: const Icon(LucideIcons.mail, size: 18),
                            label: const Text('Email'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.gapLg,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable contact row with external link indicator.
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: cs.primary),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.externalLink, size: 14, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

/// Static detail row (not tappable).
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(value, style: context.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
