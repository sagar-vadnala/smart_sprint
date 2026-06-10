import 'package:flutter/material.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_cta.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_showcase.dart';
import 'package:smart_sprint/features/landing/view/widgets/marketing_scaffold.dart';
import 'package:smart_sprint/features/landing/view/widgets/page_sections.dart';

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarketingScaffold(
      currentPath: '/teams',
      sections: [
        PageHero(
          kicker: 'Teams',
          title: 'Built for solo focus\nand team flow.',
          lede:
              'Start on your own and invite the team when you\'re ready. SmartSprint '
              'adapts — collaboration features show up exactly where they\'re useful.',
          accent: AppColors.glowTeal,
        ),
        InfoGrid(
          index: '01',
          kicker: 'Collaboration',
          heading: 'Everyone on the same page, in real time.',
          items: [
            InfoItem(Icons.person_rounded, AppColors.brand, 'Personal space',
                'A private organization that\'s just you — no avatars, no noise, pure focus.'),
            InfoItem(Icons.groups_rounded, AppColors.glowTeal, 'Shared orgs',
                'Spin up a team organization with shared spaces, sprints and tasks.'),
            InfoItem(Icons.mail_outline_rounded, AppColors.accent, 'Invite by email',
                'Add teammates in seconds; roles keep ownership and admin actions safe.'),
            InfoItem(Icons.people_alt_outlined, AppColors.info, 'Assignees',
                'Assign tasks and subtasks to one or many people, with clear avatar stacks.'),
            InfoItem(Icons.forum_outlined, AppColors.brand, 'Discuss in context',
                'Comment right on the task. The activity timeline records every change.'),
            InfoItem(Icons.swap_horiz_rounded, AppColors.glowTeal, 'Switch instantly',
                'Flip between personal and team organizations from a single switcher.'),
          ],
        ),
        LandingShowcase(),
        LandingCtaBand(),
      ],
    );
  }
}
