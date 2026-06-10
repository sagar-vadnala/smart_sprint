import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/theme/theme_cubit.dart';
import 'package:smart_sprint/core/utils/responsive.dart';
import 'package:smart_sprint/features/auth/data/auth_repository.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/view/widgets/member_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final user = state.currentUser;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final myTasks = state.allTasks
        .where((t) => t.assigneeIds.contains(state.currentUserId))
        .toList();
    final open = myTasks.where((t) => !t.isDone).length;
    final done = myTasks.where((t) => t.isDone).length;
    final orgs = state.organizations.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              // Identity header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      user.avatarColor.withValues(alpha: 0.22),
                      user.avatarColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: context.useSideNav
                    ? Row(
                        children: [
                          MemberAvatar(member: user, size: 72),
                          const SizedBox(width: 18),
                          Expanded(child: _identityText(context, user)),
                        ],
                      )
                    : Column(
                        children: [
                          MemberAvatar(member: user, size: 78),
                          const SizedBox(height: 14),
                          _identityText(context, user, center: true),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      value: '$open',
                      label: 'Open tasks',
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      value: '$done',
                      label: 'Completed',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      value: '$orgs',
                      label: 'Organizations',
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Appearance
              _SectionLabel('APPEARANCE'),
              const SizedBox(height: 10),
              _SettingsCard(
                child: BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, mode) => _ThemeSelector(mode: mode),
                ),
              ),
              const SizedBox(height: 22),

              // Organizations
              _SectionLabel('MY ORGANIZATIONS'),
              const SizedBox(height: 10),
              _SettingsCard(
                padded: false,
                child: Column(
                  children: [
                    for (var i = 0; i < state.organizations.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: state.organizations[i].color.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            state.organizations[i].icon,
                            color: state.organizations[i].color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          state.organizations[i].name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          state.organizations[i].type.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: muted,
                          ),
                        ),
                        trailing:
                            state.organizations[i].id ==
                                state.currentOrganizationId
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 20,
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Account
              _SectionLabel('ACCOUNT'),
              const SizedBox(height: 10),
              _SettingsCard(
                padded: false,
                child: Column(
                  children: [
                    _accountRow(
                      context,
                      Icons.notifications_outlined,
                      'Notifications',
                      'Manage alerts and reminders',
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    _accountRow(
                      context,
                      Icons.lock_outline_rounded,
                      'Privacy & security',
                      'Password, sessions, data',
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    _accountRow(
                      context,
                      Icons.help_outline_rounded,
                      'Help & support',
                      'Docs, contact, feedback',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Sign out
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthRepository().logout();
                  if (context.mounted) context.go('/login');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'SmartSprint · v1.0.0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityText(
    BuildContext context,
    dynamic user, {
    bool center = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          user.id == 'me' ? 'You' : user.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: muted),
        ),
      ],
    );
  }

  Widget _accountRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return ListTile(
      leading: Icon(icon, size: 21, color: muted),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: muted),
      ),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: muted),
      onTap: () {},
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: muted,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool padded;

  const _SettingsCard({required this.child, this.padded = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padded ? const EdgeInsets.all(6) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: child,
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode mode;

  const _ThemeSelector({required this.mode});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    Widget option(ThemeMode m, IconData icon, String label) {
      final selected = m == mode;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = isDark ? AppColors.darkText : AppColors.lightText;
      final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
      return Expanded(
        child: GestureDetector(
          onTap: () => switch (m) {
            ThemeMode.light => cubit.setLight(),
            ThemeMode.dark => cubit.setDark(),
            ThemeMode.system => cubit.setSystem(),
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.brand.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected
                    ? AppColors.brand
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: 1.4,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: selected ? AppColors.brand : muted),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.brand : textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
        option(ThemeMode.light, Icons.light_mode_outlined, 'Light'),
        option(ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
      ],
    );
  }
}
