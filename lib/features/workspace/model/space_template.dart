import 'package:flutter/material.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';

/// A sprint a template should generate. Dates are expressed as offsets from the
/// moment the space is created so generated content always looks "current".
class TemplateSprint {
  final String name;
  final String goal;
  final int startOffsetDays;
  final int durationDays;

  const TemplateSprint({
    required this.name,
    this.goal = '',
    this.startOffsetDays = 0,
    this.durationDays = 14,
  });
}

/// A task a template should generate. [sprintIndex] points into the template's
/// [SpaceTemplate.sprints]; null means it lands in the backlog.
class TemplateTask {
  final String title;
  final String description;
  final int? sprintIndex;
  final TaskStatus status;
  final TaskPriority priority;
  final int? dueInDays;

  const TemplateTask({
    required this.title,
    this.description = '',
    this.sprintIndex,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.normal,
    this.dueInDays,
  });
}

/// A pickable blueprint for a new space. Selecting one creates the workspace and
/// pre-populates it with sprints + tasks (unless [isBlank]).
class SpaceTemplate {
  final String id;
  final String name;
  final String tagline;

  /// Icon shown on the gallery card.
  final IconData icon;

  /// Default accent colour + glyph applied to the created space's badge.
  final Color accent;
  final IconData spaceIcon;

  final List<TemplateSprint> sprints;
  final List<TemplateTask> tasks;

  const SpaceTemplate({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.accent,
    required this.spaceIcon,
    this.sprints = const [],
    this.tasks = const [],
  });

  bool get isBlank => sprints.isEmpty && tasks.isEmpty;

  int get taskCount => tasks.length;
  int get sprintCount => sprints.length;
}

/// The built-in templates offered in the gallery.
const List<SpaceTemplate> kSpaceTemplates = [
  _blank,
  _sprintProduct,
  _bugTracking,
  _marketing,
];

const _blank = SpaceTemplate(
  id: 'blank',
  name: 'Blank Space',
  tagline: 'Start from scratch with an empty space.',
  icon: Icons.add_rounded,
  accent: Color(0xFF6C47FF),
  spaceIcon: Icons.folder_rounded,
);

const _sprintProduct = SpaceTemplate(
  id: 'sprint_product',
  name: 'Sprint / Product Management',
  tagline: 'Agile sprints, a groomed backlog, and a roadmap to ship faster.',
  icon: Icons.rocket_launch_rounded,
  accent: Color(0xFF6C47FF),
  spaceIcon: Icons.rocket_launch_rounded,
  sprints: [
    TemplateSprint(
      name: 'Sprint 1',
      goal: 'Ship the onboarding revamp',
      startOffsetDays: 0,
      durationDays: 14,
    ),
    TemplateSprint(
      name: 'Sprint 2',
      goal: 'Stabilise & polish',
      startOffsetDays: 14,
      durationDays: 14,
    ),
  ],
  tasks: [
    TemplateTask(
      title: 'Define sprint goal & scope',
      description: 'Align the team on what "done" looks like this sprint.',
      sprintIndex: 0,
      status: TaskStatus.done,
      priority: TaskPriority.high,
      dueInDays: 1,
    ),
    TemplateTask(
      title: 'Design new onboarding flow',
      description: 'Wireframes → hi-fi for the first-run experience.',
      sprintIndex: 0,
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueInDays: 5,
    ),
    TemplateTask(
      title: 'Implement welcome screen',
      sprintIndex: 0,
      status: TaskStatus.inProgress,
      priority: TaskPriority.normal,
      dueInDays: 7,
    ),
    TemplateTask(
      title: 'Wire up analytics events',
      sprintIndex: 0,
      status: TaskStatus.todo,
      priority: TaskPriority.normal,
      dueInDays: 9,
    ),
    TemplateTask(
      title: 'QA pass on onboarding',
      sprintIndex: 0,
      status: TaskStatus.inReview,
      priority: TaskPriority.normal,
      dueInDays: 12,
    ),
    TemplateTask(
      title: 'Performance audit',
      description: 'Profile cold-start and trim the critical path.',
      sprintIndex: 1,
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      dueInDays: 18,
    ),
    TemplateTask(
      title: 'Accessibility review',
      sprintIndex: 1,
      status: TaskStatus.todo,
      priority: TaskPriority.normal,
      dueInDays: 20,
    ),
    TemplateTask(
      title: 'Roadmap: Q2 themes',
      description: 'Draft the next quarter\'s big bets for review.',
      status: TaskStatus.todo,
      priority: TaskPriority.low,
    ),
    TemplateTask(
      title: 'Backlog: dark mode polish',
      status: TaskStatus.todo,
      priority: TaskPriority.low,
    ),
    TemplateTask(
      title: 'Backlog: keyboard shortcuts',
      status: TaskStatus.todo,
      priority: TaskPriority.low,
    ),
  ],
);

const _bugTracking = SpaceTemplate(
  id: 'bug_tracking',
  name: 'Bug Tracking',
  tagline: 'Triage, prioritise, and burn down defects with a clear pipeline.',
  icon: Icons.bug_report_rounded,
  accent: Color(0xFFEF4444),
  spaceIcon: Icons.bug_report_rounded,
  tasks: [
    TemplateTask(
      title: 'Login fails on Safari 16',
      description: 'OAuth redirect loops back to /login intermittently.',
      status: TaskStatus.todo,
      priority: TaskPriority.urgent,
      dueInDays: 1,
    ),
    TemplateTask(
      title: 'Crash when opening empty project',
      status: TaskStatus.todo,
      priority: TaskPriority.urgent,
      dueInDays: 1,
    ),
    TemplateTask(
      title: 'Avatar images not loading on slow networks',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueInDays: 3,
    ),
    TemplateTask(
      title: 'Date picker off-by-one in UTC+13',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueInDays: 4,
    ),
    TemplateTask(
      title: 'Search highlights wrong term',
      status: TaskStatus.inReview,
      priority: TaskPriority.normal,
      dueInDays: 5,
    ),
    TemplateTask(
      title: 'Tooltip clips at viewport edge',
      status: TaskStatus.inReview,
      priority: TaskPriority.low,
      dueInDays: 6,
    ),
    TemplateTask(
      title: 'Fix flaky checkout integration test',
      status: TaskStatus.done,
      priority: TaskPriority.normal,
    ),
    TemplateTask(
      title: 'Resolve memory leak in board view',
      status: TaskStatus.done,
      priority: TaskPriority.high,
    ),
  ],
);

const _marketing = SpaceTemplate(
  id: 'marketing',
  name: 'Marketing',
  tagline: 'Plan campaigns, content, and launches in one place.',
  icon: Icons.campaign_rounded,
  accent: Color(0xFFF59E0B),
  spaceIcon: Icons.campaign_rounded,
  sprints: [
    TemplateSprint(
      name: 'Q2 Launch Campaign',
      goal: 'Drive 10k signups from the spring launch',
      startOffsetDays: 0,
      durationDays: 30,
    ),
  ],
  tasks: [
    TemplateTask(
      title: 'Define campaign messaging & positioning',
      sprintIndex: 0,
      status: TaskStatus.done,
      priority: TaskPriority.high,
      dueInDays: 2,
    ),
    TemplateTask(
      title: 'Design landing page',
      sprintIndex: 0,
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueInDays: 6,
    ),
    TemplateTask(
      title: 'Write launch blog post',
      sprintIndex: 0,
      status: TaskStatus.inProgress,
      priority: TaskPriority.normal,
      dueInDays: 8,
    ),
    TemplateTask(
      title: 'Schedule social media calendar',
      sprintIndex: 0,
      status: TaskStatus.todo,
      priority: TaskPriority.normal,
      dueInDays: 10,
    ),
    TemplateTask(
      title: 'Set up email drip sequence',
      sprintIndex: 0,
      status: TaskStatus.todo,
      priority: TaskPriority.normal,
      dueInDays: 12,
    ),
    TemplateTask(
      title: 'Brief paid ads agency',
      sprintIndex: 0,
      status: TaskStatus.todo,
      priority: TaskPriority.low,
      dueInDays: 14,
    ),
    TemplateTask(
      title: 'Post-launch retro & report',
      status: TaskStatus.todo,
      priority: TaskPriority.low,
    ),
  ],
);
