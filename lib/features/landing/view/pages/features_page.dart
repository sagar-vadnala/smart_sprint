import 'package:flutter/material.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_cta.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_showcase.dart';
import 'package:smart_sprint/features/landing/view/widgets/marketing_scaffold.dart';
import 'package:smart_sprint/features/landing/view/widgets/page_sections.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarketingScaffold(
      currentPath: '/features',
      sections: [
        PageHero(
          kicker: 'Features',
          title: 'Everything you need to plan, track and ship.',
          lede:
              'SmartSprint is a focused project workspace — tasks, sprints, nested '
              'subtasks, discussion and search, all designed to work together.',
        ),
        InfoGrid(
          index: '01',
          kicker: 'The essentials',
          heading: 'Capabilities that cover the whole workflow.',
          items: [
            InfoItem(Icons.check_circle_outline, AppColors.brand, 'Statuses that flow',
                'To do, In progress, In review and Done — change status inline from a list or a board.'),
            InfoItem(Icons.bolt_rounded, AppColors.accent, 'Sprints & backlog',
                'Plan work into sprints, focus the active one, keep the backlog a tap away.'),
            InfoItem(Icons.account_tree_outlined, AppColors.glowTeal, 'Nested subtasks',
                'Recursive subtasks, each with its own status, assignees, priority and due date.'),
            InfoItem(Icons.flag_rounded, AppColors.error, 'Priorities',
                'Urgent, High, Normal and Low flags so the right work rises to the top.'),
            InfoItem(Icons.forum_outlined, AppColors.info, 'Activity & comments',
                'A live, per-task timeline plus threaded comments keep context attached to the work.'),
            InfoItem(Icons.workspaces_outline, AppColors.brand, 'Orgs & workspaces',
                'Organize work into spaces inside personal or shared organizations.'),
            InfoItem(Icons.search_rounded, AppColors.accent, 'Command search',
                'A keyboard-first palette that finds any space or task across the org instantly.'),
            InfoItem(Icons.dark_mode_outlined, AppColors.glowTeal, 'Dark & light',
                'A crafted dark and light theme — switch any time, your preference sticks.'),
            InfoItem(Icons.devices_rounded, AppColors.info, 'Web & mobile',
                'One product, native on mobile and fast on the web. Pick up wherever you left off.'),
          ],
        ),
        LandingShowcase(),
        LandingMetrics(),
        LandingCtaBand(),
      ],
    );
  }
}
