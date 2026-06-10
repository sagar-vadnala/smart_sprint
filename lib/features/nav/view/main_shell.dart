import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/theme/theme_cubit.dart';
import 'package:smart_sprint/core/utils/nav.dart';
import 'package:smart_sprint/core/utils/responsive.dart';
import 'package:smart_sprint/core/widgets/app_background.dart';
import 'package:smart_sprint/core/widgets/brand_loader.dart';
import 'package:smart_sprint/features/home/view/home_screen.dart';
import 'package:smart_sprint/features/nav/cubit/nav_cubit.dart';
import 'package:smart_sprint/features/nav/cubit/sidebar_cubit.dart';
import 'package:smart_sprint/features/nav/view/sidebar_spaces.dart';
import 'package:smart_sprint/features/search/view/search_screen.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_state.dart';
import 'package:smart_sprint/features/workspace/view/inbox_screen.dart';
import 'package:smart_sprint/features/workspace/view/my_tasks_screen.dart';
import 'package:smart_sprint/features/workspace/view/spaces_screen.dart';
import 'package:smart_sprint/features/workspace/view/widgets/create_sheets.dart';
import 'package:smart_sprint/features/workspace/view/widgets/member_avatar.dart';
import 'package:smart_sprint/features/workspace/view/widgets/organization_switcher.dart';

/// The persistent shell rendered around every URL route inside the app's
/// ShellRoute (see [AppRouter]). Provides nav/sidebar cubits, paints the
/// ambient background, and adds:
///   • a glass side rail on web
///   • a glass bottom nav on mobile (only on /home so detail screens stay
///     focused)
/// The current page is passed in as [child] by go_router.
class MainShellHost extends StatelessWidget {
  final Widget child;

  const MainShellHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavCubit()),
        BlocProvider(create: (_) => SidebarCubit()),
      ],
      child: _ShellChrome(child: child),
    );
  }
}

const _navDestinations = [
  (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Home'),
  (
    icon: Icons.grid_view_outlined,
    active: Icons.grid_view_rounded,
    label: 'Workspaces',
  ),
  (
    icon: Icons.check_circle_outline_rounded,
    active: Icons.check_circle_rounded,
    label: 'My Tasks',
  ),
  (
    icon: Icons.notifications_none_rounded,
    active: Icons.notifications_rounded,
    label: 'Inbox',
  ),
];

class _ShellChrome extends StatelessWidget {
  final Widget child;

  const _ShellChrome({required this.child});

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<WorkspaceBloc, bool>((b) => b.state.loaded);

    if (!loaded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: const Center(
            child: BrandLoader(size: 72, label: 'Loading your workspace…'),
          ),
        ),
      );
    }

    // During a redirect the shell can rebuild for a frame while it's momentarily
    // outside a route subtree, where GoRouterState.of throws. Guard it.
    String loc;
    try {
      loc = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      loc = '/home';
    }
    final isHome = loc == '/home';

    // ── Wide layout: persistent side rail + centred content ──
    if (context.useSideNav) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Row(
            children: [
              const _SideNav(),
              // Content fills the remaining width (no centred max-width gutter,
              // like ClickUp). Individual screens manage their own padding.
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    // ── Narrow layout: bottom nav only on /home; details go full-screen ──
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: isHome,
      body: AppBackground(child: child),
      bottomNavigationBar: isHome ? const _BottomNavBar() : null,
    );
  }
}

/// Selects a tab AND ensures we're on the /home route — so tapping a tab from
/// inside a detail screen (/t/:id, /w/:id, /profile, /search) pops back to the
/// tabs and switches at the same time.
///
/// Only navigates when we're NOT already on /home. On the web, `go('/home')`
/// pushes a *new* browser-history entry every time (even to the same URL), so
/// calling it unconditionally made the back button require N presses to leave.
/// The tab itself is the IndexedStack driven by NavCubit, so when we're already
/// on /home we just switch the cubit — no navigation needed.
void _switchTab(BuildContext context, int index) {
  context.read<NavCubit>().select(index);
  final onHome = GoRouterState.of(context).matchedLocation == '/home';
  if (!onHome) context.go('/home');
}

/// The 4 main tabs. Rendered as the /home route's content; an IndexedStack so
/// switching tabs preserves each tab's widget state.
class HomeShellPage extends StatelessWidget {
  const HomeShellPage({super.key});

  static const _tabs = [
    HomeScreen(),
    SpacesScreen(),
    MyTasksScreen(),
    InboxScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = context.watch<NavCubit>().state;
    return IndexedStack(index: index, children: _tabs);
  }
}

// ─── Side navigation (web / desktop / tablet) ─────────────────────────────────

class _SideNav extends StatelessWidget {
  const _SideNav();

  @override
  Widget build(BuildContext context) {
    final index = context.watch<NavCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final badge = state.myOverdueCount + state.myDueTodayCount;
    final sidebar = context.watch<SidebarCubit>().state;
    final glass = (isDark ? AppColors.darkSurface : Colors.white).withValues(
      alpha: isDark ? 0.55 : 0.7,
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 264,
          decoration: BoxDecoration(
            color: glass,
            border: Border(right: BorderSide(color: border, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 18),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF8B6FFF), AppColors.brand],
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'SmartSprint',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Org switcher
                  const OrganizationPill(),
                  const SizedBox(height: 10),

                  // Search
                  GestureDetector(
                    onTap: () => openSearch(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkFill
                            : AppColors.lightFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: muted),
                          const SizedBox(width: 9),
                          Text(
                            'Search',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Create
                  ElevatedButton.icon(
                    onPressed: () => showCreateMenu(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      alignment: Alignment.center,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('Create'),
                  ),
                  const SizedBox(height: 18),

                  // Scrollable: nav items + spaces tree + recents
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (var i = 0; i < _navDestinations.length; i++)
                          _SideNavItem(
                            icon: _navDestinations[i].icon,
                            activeIcon: _navDestinations[i].active,
                            label: _navDestinations[i].label,
                            selected:
                                index == i &&
                                GoRouterState.of(context).matchedLocation ==
                                    '/home',
                            badge: i == 3 ? badge : 0,
                            onTap: () => _switchTab(context, i),
                          ),
                        if (sidebar.showSpaces) const SidebarSpaces(),
                        if (sidebar.showRecents) const _QuickAccess(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Customize sidebar
                  _HoverNavRow(
                    icon: Icons.tune_rounded,
                    label: 'Customize sidebar',
                    onTap: () => showCustomizeSidebar(context),
                  ),

                  // Footer: theme toggle + user
                  Divider(color: border, height: 24),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.pushUnique('/profile'),
                    child: Row(
                      children: [
                        MemberAvatar(member: state.currentUser, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.currentUser.id == 'me'
                                    ? 'You'
                                    : state.currentUser.firstName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.lightText,
                                ),
                              ),
                              Text(
                                state.currentUser.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 19,
                            color: muted,
                          ),
                          onPressed: () => context.read<ThemeCubit>().toggle(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain icon+label row (no selection state) used for utility actions.
class _HoverNavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HoverNavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        hoverColor: (isDark ? Colors.white : Colors.black).withValues(
          alpha: 0.05,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 19, color: muted),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? AppColors.brand.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 20,
                  color: selected ? AppColors.brand : muted,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.brand : textColor,
                  ),
                ),
                const Spacer(),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '$badge',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quick access (recently opened workspaces, with breadcrumb) ───────────────

class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WorkspaceBloc>().state;
    final recents = state.recentWorkspaces.take(3).toList();
    if (recents.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
          child: Text(
            'QUICK ACCESS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: muted,
            ),
          ),
        ),
        ...recents.map((p) => _QuickAccessRow(project: p)),
      ],
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  final dynamic project; // Project

  const _QuickAccessRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final org = state.currentOrganization;
    final sprint = state.activeSprintForProject(project.id as String);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => context.pushUnique('/w/${project.id as String}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: (project.color as Color).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  project.icon as IconData,
                  size: 16,
                  color: project.color as Color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb: org › (sprint)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            org.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                        ),
                        if (sprint != null) ...[
                          Text(
                            '  ›  ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: muted,
                            ),
                          ),
                          const Icon(
                            Icons.bolt_rounded,
                            size: 10,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              sprint.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      project.name as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom navigation (mobile) ───────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final index = context.watch<NavCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final glass = (isDark ? AppColors.darkSurface : Colors.white).withValues(
      alpha: isDark ? 0.7 : 0.8,
    );

    final unreadCount = context.select<WorkspaceBloc, int>(
      (b) => b.state.myOverdueCount + b.state.myDueTodayCount,
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: glass,
            border: Border(top: BorderSide(color: border, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  _NavItem(
                    icon: _navDestinations[0].icon,
                    activeIcon: _navDestinations[0].active,
                    label: 'Home',
                    selected: index == 0,
                    onTap: () => _switchTab(context, 0),
                  ),
                  _NavItem(
                    icon: _navDestinations[1].icon,
                    activeIcon: _navDestinations[1].active,
                    label: 'Spaces',
                    selected: index == 1,
                    onTap: () => _switchTab(context, 1),
                  ),
                  const _CreateButton(),
                  _NavItem(
                    icon: _navDestinations[2].icon,
                    activeIcon: _navDestinations[2].active,
                    label: 'My Tasks',
                    selected: index == 2,
                    onTap: () => _switchTab(context, 2),
                  ),
                  _NavItem(
                    icon: _navDestinations[3].icon,
                    activeIcon: _navDestinations[3].active,
                    label: 'Inbox',
                    selected: index == 3,
                    badge: unreadCount,
                    onTap: () => _switchTab(context, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = AppColors.brand;
    final inactive = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final color = selected ? activeColor : inactive;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, size: 23, color: color),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 15),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: () => showCreateMenu(context),
          child: Container(
            width: 46,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B6FFF), AppColors.brand],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Helper so tabs can switch programmatically (e.g. "View all tasks").
extension ShellNav on BuildContext {
  void goToTab(int index) => read<NavCubit>().select(index);
  WorkspaceState get ws => read<WorkspaceBloc>().state;
}
