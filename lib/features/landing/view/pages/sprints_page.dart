import 'package:flutter/material.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_cta.dart';
import 'package:smart_sprint/features/landing/view/widgets/marketing_scaffold.dart';
import 'package:smart_sprint/features/landing/view/widgets/page_sections.dart';

class SprintsPage extends StatelessWidget {
  const SprintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarketingScaffold(
      currentPath: '/sprints',
      sections: [
        PageHero(
          kicker: 'Sprints',
          title: 'Plan in sprints.\nShip on a cadence.',
          lede:
              'Stop drowning in an endless backlog. Pull the work that matters into '
              'a sprint, focus the team, and watch it move to Done.',
          accent: AppColors.accent,
        ),
        StepList(
          index: '01',
          kicker: 'How it works',
          heading: 'From idea to shipped in four steps.',
          steps: [
            ('Capture into the backlog',
                'Drop every idea, bug and request into the backlog so nothing is lost — no pressure to schedule it yet.'),
            ('Plan the sprint',
                'Pull the highest-priority work into a sprint, assign owners and set due dates in seconds.'),
            ('Focus on what\'s active',
                'Filter the board to the active sprint. The team sees exactly what to work on next, nothing more.'),
            ('Review and ship',
                'Move work through In review to Done, track progress per sprint, then roll the rest forward.'),
          ],
        ),
        InfoGrid(
          index: '02',
          kicker: 'Built for momentum',
          heading: 'Everything a sprint needs, nothing it doesn\'t.',
          items: [
            InfoItem(Icons.view_week_outlined, AppColors.accent, 'Sprint filters',
                'Jump between sprints and the backlog with a single chip — your board reshapes instantly.'),
            InfoItem(Icons.view_kanban_outlined, AppColors.brand, 'List or Board',
                'See the sprint as a tidy list or a visual board and switch with one click.'),
            InfoItem(Icons.trending_up_rounded, AppColors.glowTeal, 'Progress at a glance',
                'Each sprint shows how much is done, so standups take seconds, not minutes.'),
          ],
        ),
        LandingCtaBand(),
      ],
    );
  }
}
