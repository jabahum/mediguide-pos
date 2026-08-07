import 'package:flutter/material.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/shared/models/enum_extensions.dart';
import 'package:user_app/features/consultants/data/models/consultant.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_button.dart';
import 'package:user_app/shared/widgets/section_group.dart';
import 'package:user_app/shared/widgets/user_avatar.dart';

class ConsultantDetailModal extends StatelessWidget {
  final Consultant consultant;

  const ConsultantDetailModal({super.key, required this.consultant});

  static Future<void> show(BuildContext context, Consultant consultant) {
    return showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => Dialog.fullscreen(
        child: ConsultantDetailModal(consultant: consultant),
      ),
    );
  }

  bool get _isActive => consultant.status.name.toLowerCase() == 'active';

  bool get _canStartChat => consultant.userAccount != null;

  String get _specialtyName =>
      consultant.specialty?.displayName ?? 'generalPractice'.tr;

  String get _location {
    final parts = [
      consultant.city,
      consultant.region,
      consultant.country,
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('consultantDetails'.tr),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: AppNavigator.pop,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _ProfileHeader(
              consultant: consultant,
              isActive: _isActive,
              specialtyName: _specialtyName,
            ),

            AppSpacing.gapLg,

            _StatsRow(
              isActive: _isActive,
              rating: consultant.rating,
              yearsOfExperience: consultant.yearsOfExperience,
            ),

            AppSpacing.gapLg,

            AppButton(
              text: 'startChat'.tr,
              icon: LucideIcons.messageSquare,
              width: double.infinity,
              onPressed: _canStartChat ? _startChatWithConsultant : null,
            ),

            if (!_canStartChat) ...[
              AppSpacing.gapSm,
              Text(
                'consultantChatUnavailable'.tr,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],

            if (_hasContactInfo) ...[
              AppSpacing.gapLg,
              SectionGroup(
                title: 'contactLocation'.tr,
                items: [
                  if (consultant.phone.trim().isNotEmpty)
                    _InfoRow(
                      icon: LucideIcons.phone,
                      label: 'phone'.tr,
                      value: consultant.phone,
                    ),
                  if (consultant.email.trim().isNotEmpty)
                    _InfoRow(
                      icon: LucideIcons.mail,
                      label: 'email'.tr,
                      value: consultant.email,
                    ),
                  if (_location.isNotEmpty)
                    _InfoRow(
                      icon: LucideIcons.mapPin,
                      label: 'location'.tr,
                      value: _location,
                    ),
                ],
              ),
            ],

            if (_hasProfessionalInfo) ...[
              AppSpacing.gapMd,
              SectionGroup(
                title: 'professionalInfo'.tr,
                items: [
                  if (consultant.licenseNumber.trim().isNotEmpty)
                    _InfoRow(
                      icon: LucideIcons.award,
                      label: 'licenseNumber'.tr,
                      value: consultant.licenseNumber,
                    ),
                  if (consultant.certifications.trim().isNotEmpty)
                    _InfoRow(
                      icon: LucideIcons.graduationCap,
                      label: 'certifications'.tr,
                      value: consultant.certifications,
                    ),
                  if (consultant.preferredLanguage != null)
                    _InfoRow(
                      icon: LucideIcons.globe,
                      label: 'preferredLanguage'.tr,
                      value:
                          consultant.preferredLanguage?.displayName ??
                          'English',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasContactInfo =>
      consultant.phone.trim().isNotEmpty ||
      consultant.email.trim().isNotEmpty ||
      _location.isNotEmpty;

  bool get _hasProfessionalInfo =>
      consultant.licenseNumber.trim().isNotEmpty ||
      consultant.certifications.trim().isNotEmpty ||
      consultant.preferredLanguage != null;

  void _startChatWithConsultant() {
    final userAccount = consultant.userAccount;

    if (userAccount == null) {
      AppMessage.error(
        AppKeys.navigatorKey.currentContext!,
        'consultantChatUnavailable'.tr,
      );

      return;
    }

    AppNavigator.pop();

    AppNavigator.push(AppRoutes.chat(userAccount.id), extra: userAccount);
  }
}

class _ProfileHeader extends StatelessWidget {
  final Consultant consultant;
  final bool isActive;
  final String specialtyName;

  const _ProfileHeader({
    required this.consultant,
    required this.isActive,
    required this.specialtyName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Column(
      children: [
        Stack(
          children: [
            UserAvatar(name: consultant.name, radius: 44),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : cs.outlineVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 3),
                ),
              ),
            ),
          ],
        ),

        AppSpacing.gapMd,

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                consultant.name,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (consultant.isVerified) ...[
              const SizedBox(width: 6),
              Icon(LucideIcons.badgeCheck, size: 20, color: cs.primary),
            ],
          ],
        ),

        const SizedBox(height: 4),

        Text(
          specialtyName,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),

        if (consultant.organization.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            consultant.organization,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final bool isActive;
  final double rating;
  final num yearsOfExperience;

  const _StatsRow({
    required this.isActive,
    required this.rating,
    required this.yearsOfExperience,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _StatPill(
          label: '${yearsOfExperience.toStringAsFixed(0)} yrs',
          icon: LucideIcons.briefcase,
        ),
        if (rating > 0)
          _StatPill(label: rating.toStringAsFixed(1), icon: LucideIcons.star),
        _StatPill(
          label: isActive ? 'available'.tr : 'offline'.tr,
          icon: isActive ? LucideIcons.circle : LucideIcons.circleOff,
          color: isActive ? Colors.green : cs.error,
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _StatPill({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final effectiveColor = color ?? cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
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
          Icon(icon, size: 17, color: cs.onSurfaceVariant),
          AppSpacing.hGapSm,
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
