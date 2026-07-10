import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/routes/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../core/usecases/usecase.dart';
import '../../features/academics/presentation/providers/appeals_controller.dart';
import '../../features/academics/presentation/providers/career_data_providers.dart';
import '../../features/academics/presentation/providers/questionnaires_provider.dart';
import '../../features/academics/presentation/providers/tuition_providers.dart';
import '../../features/auth/presentation/mappers/career_account_mapper.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/profile/presentation/providers/student_badge_providers.dart';
import '../../features/timetable/presentation/providers/timetable_providers.dart';
import '../widgets/avatar_profile_panel/avatar_profile_panel_widget.dart';

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Size get preferredSize => const Size.fromHeight(78);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).value;
    final photoSrc = ref.watch(studentProfilePhotoProvider).value;

    final activeId = session?.activeProfile == null
        ? null
        : careerAccountId(session!.activeProfile!);

    final accounts = session == null
        ? const <AccountEntry>[]
        : session.profiles.map((profile) {
      final isCurrent = careerAccountId(profile) == activeId;
      return mapCareerProfileToAccountEntry(
        profile,
        fullName: session.fullName,
        email: session.username,
        isCurrent: isCurrent,
        avatarSrc: photoSrc,
      );
    }).toList(growable: false);

    return Material(
      color: AppColors.secondary.withValues(alpha: 0.38),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.92),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _TopBarGroup(
                children: [
                  AvatarProfilePanelWidget(
                    accounts: accounts,
                    position: PanelPosition.right,
                    animation: PanelAnimation.ios,
                    showSettings: false,
                    showLogout: true,
                    showAddAccount: false,
                    onProfileClick: () =>
                        context.pushNamed(AppRoutes.profileName),
                    onAccountSwitch: (account) async {
                      if (session == null) return;

                      final profile = findCareerProfileById(
                        session.profiles,
                        account.id,
                      );
                      if (profile == null) return;
                      if (careerAccountId(profile) == activeId) {
                        return;
                      }

                      await ref
                          .read(authSessionProvider.notifier)
                          .switchCareer(profile);

                      ref.invalidate(careerSnapshotProvider);
                      ref.invalidate(studentBadgeProvider);
                      ref.invalidate(studentProfilePhotoProvider);
                      ref.invalidate(tuitionSnapshotProvider);
                      ref.invalidate(remoteQuestionnairesProvider);
                      ref.invalidate(studentTimetablesProvider);
                      ref.invalidate(suggestedExamsProvider);
                      ref.invalidate(appealsControllerProvider);
                      final appealsNotifier = ref.read(
                        appealsControllerProvider.notifier,
                      );
                      unawaited(appealsNotifier.loadAvailableAppeals());
                      unawaited(appealsNotifier.loadBookingHistory());
                    },
                    onLogoutClick: () async {
                      await ref
                          .read(logoutUseCaseProvider)
                          .call(const NoParams());

                      ref.invalidate(authSessionProvider);

                      if (!context.mounted) return;

                      ref
                          .read(isAuthenticatedProvider.notifier)
                          .setAuthenticated(false);

                      context.goNamed(AppRoutes.loginName);
                    },
                  ),
                  const SizedBox(width: 14),
                  _TopBarAction(
                    icon: LucideIcons.search,
                    tooltip: 'Cerca',
                    color: AppColors.colorPrimaryDark,
                    hasSoftBackground: true,
                    onTap: () {},
                  ),
                ],
              ),
              const Spacer(),
              _TopBarGroup(
                children: [
                  _TopBarAction(
                    icon: LucideIcons.heart,
                    tooltip: 'Preferiti',
                    color: AppColors.colorTertiaryDark,
                    onTap: () => context.pushNamed(AppRoutes.preferitiName),
                  ),
                  const SizedBox(width: 14),
                  _TopBarAction(
                    icon: LucideIcons.menu,
                    tooltip: 'Menu',
                    color: AppColors.colorPrimaryDark,
                    onTap: () => scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarGroup extends StatelessWidget {
  const _TopBarGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
    this.hasSoftBackground = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  final bool hasSoftBackground;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasSoftBackground
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 23),
          ),
        ),
      ),
    );
  }
}