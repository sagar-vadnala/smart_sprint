import 'package:flutter/material.dart';
import 'package:smart_sprint/features/workspace/model/activity.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/organization.dart';
import 'package:smart_sprint/features/workspace/model/project.dart';
import 'package:smart_sprint/features/workspace/model/sprint.dart';
import 'package:smart_sprint/features/workspace/model/subtask.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'package:smart_sprint/features/workspace/model/team_member.dart';

/// In-memory seed. The first member ('me') is the signed-in user.
///
/// Hierarchy: Organization → Workspace (the [Project] class) → Sprint → Task.
/// Ships a Personal org (just you) and a "Hikigai" team org you're invited to,
/// each holding several workspaces. Opens on Personal — the solo experience.
abstract final class SeedData {
  static const currentUserId = 'me';
  static const personalOrgId = 'org_personal';
  static const hikigaiOrgId = 'org_hikigai';
  static const defaultOrganizationId = personalOrgId;

  static const members = <TeamMember>[
    TeamMember(
      id: 'me',
      name: 'You',
      email: 'you@smartsprint.app',
      role: 'Product Manager',
      avatarColor: Color(0xFF6C47FF),
    ),
    TeamMember(
      id: 'm2',
      name: 'Aanya Rao',
      email: 'aanya@hikigai.ai',
      role: 'Lead Designer',
      avatarColor: Color(0xFF34D399),
    ),
    TeamMember(
      id: 'm3',
      name: 'Jordan Lee',
      email: 'jordan@hikigai.ai',
      role: 'Backend Engineer',
      avatarColor: Color(0xFFFBBF24),
    ),
    TeamMember(
      id: 'm4',
      name: 'Riya Sharma',
      email: 'riya@hikigai.ai',
      role: 'Frontend Engineer',
      avatarColor: Color(0xFFF472B6),
    ),
    TeamMember(
      id: 'm5',
      name: 'Marcus Cole',
      email: 'marcus@hikigai.ai',
      role: 'QA Engineer',
      avatarColor: Color(0xFF60A5FA),
    ),
  ];

  static const organizations = <Organization>[
    Organization(
      id: personalOrgId,
      name: 'Personal',
      type: OrgType.personal,
      color: Color(0xFF6C47FF),
      icon: Icons.person_rounded,
      memberIds: ['me'],
    ),
    Organization(
      id: hikigaiOrgId,
      name: 'Hikigai',
      type: OrgType.team,
      color: Color(0xFF14B8A6),
      icon: Icons.hexagon_rounded,
      memberIds: ['me', 'm2', 'm3', 'm4', 'm5'],
    ),
  ];

  // Projects = "Workspaces" in the UI.
  static const projects = <Project>[
    // ── Personal org ──
    Project(
      id: 'pp1',
      organizationId: personalOrgId,
      name: 'Personal',
      description: 'Errands, admin, and life logistics',
      color: Color(0xFF6C47FF),
      icon: Icons.check_circle_rounded,
      memberIds: ['me'],
    ),
    Project(
      id: 'pp2',
      organizationId: personalOrgId,
      name: 'Side Project',
      description: 'My weekend app — ship v1',
      color: Color(0xFFEC4899),
      icon: Icons.rocket_launch_rounded,
      memberIds: ['me'],
    ),
    Project(
      id: 'pp3',
      organizationId: personalOrgId,
      name: 'Learning',
      description: 'Courses, books, and practice',
      color: Color(0xFF14B8A6),
      icon: Icons.school_rounded,
      memberIds: ['me'],
    ),
    // ── Hikigai org ──
    Project(
      id: 'p1',
      organizationId: hikigaiOrgId,
      name: 'Mobile App',
      description: 'iOS & Android client for SmartSprint',
      color: Color(0xFF6C47FF),
      icon: Icons.phone_iphone_rounded,
      memberIds: ['me', 'm2', 'm4', 'm5'],
    ),
    Project(
      id: 'p2',
      organizationId: hikigaiOrgId,
      name: 'Design System',
      description: 'Shared components, tokens, and guidelines',
      color: Color(0xFF14B8A6),
      icon: Icons.palette_rounded,
      memberIds: ['me', 'm2'],
    ),
    Project(
      id: 'p3',
      organizationId: hikigaiOrgId,
      name: 'API Platform',
      description: 'Core services, auth, and integrations',
      color: Color(0xFFF59E0B),
      icon: Icons.dns_rounded,
      memberIds: ['me', 'm3', 'm5'],
    ),
  ];

  static List<Sprint> sprints() {
    final now = DateTime.now();
    return [
      // Personal — solo users can run sprints too.
      Sprint(
        id: 'sp_launch',
        name: 'Launch Push',
        goal: 'Get Side Project v1 out the door',
        projectId: 'pp2',
        startDate: now.subtract(const Duration(days: 4)),
        endDate: now.add(const Duration(days: 10)),
        status: SprintStatus.active,
      ),
      // Hikigai
      Sprint(
        id: 's1',
        name: 'Sprint 23',
        goal: 'Ship onboarding & auth revamp',
        projectId: 'p1',
        startDate: now.subtract(const Duration(days: 6)),
        endDate: now.add(const Duration(days: 8)),
        status: SprintStatus.active,
      ),
      Sprint(
        id: 's2',
        name: 'Foundations',
        goal: 'Tokens, typography, color system',
        projectId: 'p2',
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 11)),
        status: SprintStatus.active,
      ),
      Sprint(
        id: 's3',
        name: 'Sprint 24',
        goal: 'Notifications & realtime sync',
        projectId: 'p1',
        startDate: now.add(const Duration(days: 9)),
        endDate: now.add(const Duration(days: 23)),
        status: SprintStatus.planned,
      ),
    ];
  }

  static List<Task> tasks() {
    final now = DateTime.now();
    DateTime day(int offset) => DateTime(now.year, now.month, now.day + offset);

    return [
      // ── Personal: Personal ──
      Task(
        id: 'pt1',
        title: 'Book dentist appointment',
        description: 'Overdue — call the clinic.',
        projectId: 'pp1',
        sprintId: null,
        status: TaskStatus.todo,
        priority: TaskPriority.normal,
        assigneeIds: ['me'],
        dueDate: day(-1),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Task(
        id: 'pt2',
        title: 'Renew gym membership',
        description: '',
        projectId: 'pp1',
        sprintId: null,
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        assigneeIds: ['me'],
        dueDate: day(2),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'pt3',
        title: 'Plan weekend trip',
        description: 'Shortlist places and book stay.',
        projectId: 'pp1',
        sprintId: null,
        status: TaskStatus.inProgress,
        priority: TaskPriority.low,
        assigneeIds: ['me'],
        dueDate: day(4),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      // ── Personal: Side Project (Launch Push) ──
      Task(
        id: 'pt4',
        title: 'Design landing page',
        description: 'Hero, features, pricing, footer.',
        projectId: 'pp2',
        sprintId: 'sp_launch',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        assigneeIds: ['me'],
        dueDate: day(1),
        createdAt: now.subtract(const Duration(days: 3)),
        subtasks: const [
          SubTask(
            id: 'pt4s1',
            title: 'Wireframe hero section',
            status: TaskStatus.done,
            assigneeIds: ['me'],
          ),
          SubTask(
            id: 'pt4s2',
            title: 'Write copy for features',
            status: TaskStatus.done,
            assigneeIds: ['me'],
          ),
          SubTask(
            id: 'pt4s3',
            title: 'Design pricing cards',
            status: TaskStatus.inProgress,
            assigneeIds: ['me'],
          ),
          SubTask(id: 'pt4s4', title: 'Build footer with links'),
        ],
      ),
      Task(
        id: 'pt5',
        title: 'Set up analytics',
        description: 'Track signups and activation.',
        projectId: 'pp2',
        sprintId: 'sp_launch',
        status: TaskStatus.todo,
        priority: TaskPriority.normal,
        assigneeIds: ['me'],
        dueDate: day(5),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'pt6',
        title: 'Write launch tweet',
        description: '',
        projectId: 'pp2',
        sprintId: 'sp_launch',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        assigneeIds: ['me'],
        dueDate: null,
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
      Task(
        id: 'pt7',
        title: 'Connect Stripe test mode',
        description: 'Sandbox checkout flow.',
        projectId: 'pp2',
        sprintId: 'sp_launch',
        status: TaskStatus.done,
        priority: TaskPriority.normal,
        assigneeIds: ['me'],
        dueDate: day(-2),
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      // ── Personal: Learning ──
      Task(
        id: 'pt8',
        title: 'Finish Flutter course · module 4',
        description: 'State management deep dive.',
        projectId: 'pp3',
        sprintId: null,
        status: TaskStatus.inProgress,
        priority: TaskPriority.normal,
        assigneeIds: ['me'],
        dueDate: day(0),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 'pt9',
        title: 'Read system design · chapter 3',
        description: 'Caching and load balancing.',
        projectId: 'pp3',
        sprintId: null,
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        assigneeIds: ['me'],
        dueDate: day(3),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'pt10',
        title: 'Practice Dart isolates',
        description: '',
        projectId: 'pp3',
        sprintId: null,
        status: TaskStatus.done,
        priority: TaskPriority.low,
        assigneeIds: ['me'],
        dueDate: day(-1),
        createdAt: now.subtract(const Duration(days: 2)),
      ),

      // ── Hikigai: Mobile App (Sprint 23) ──
      Task(
        id: 't1',
        title: 'Build onboarding carousel',
        description: 'Three-screen intro with illustrations and skip flow.',
        projectId: 'p1',
        sprintId: 's1',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        assigneeIds: ['me', 'm4'],
        dueDate: day(-2),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Task(
        id: 't2',
        title: 'Email + password login screen',
        description: 'Validation, error states, loading.',
        projectId: 'p1',
        sprintId: 's1',
        status: TaskStatus.inReview,
        priority: TaskPriority.high,
        assigneeIds: ['me'],
        dueDate: day(0),
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Task(
        id: 't3',
        title: 'Google SSO integration',
        description: 'Wire up google_sign_in and token exchange.',
        projectId: 'p1',
        sprintId: 's1',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        assigneeIds: ['m3', 'me'],
        dueDate: day(1),
        createdAt: now.subtract(const Duration(days: 3)),
        subtasks: const [
          SubTask(
            id: 't3s1',
            title: 'Add OAuth client IDs',
            status: TaskStatus.done,
            assigneeIds: ['m3'],
          ),
          SubTask(
            id: 't3s2',
            title: 'Handle token exchange',
            status: TaskStatus.inProgress,
            assigneeIds: ['m3', 'me'],
          ),
          SubTask(
            id: 't3s3',
            title: 'Wire up logout flow',
            assigneeIds: ['me'],
          ),
        ],
      ),
      Task(
        id: 't4',
        title: 'Bottom navigation shell',
        description: 'Tab bar with Home, Workspaces, Tasks, Inbox.',
        projectId: 'p1',
        sprintId: 's1',
        status: TaskStatus.inProgress,
        priority: TaskPriority.normal,
        assigneeIds: ['me'],
        dueDate: day(2),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 't5',
        title: 'Push notification setup',
        description: 'FCM config + permission prompt.',
        projectId: 'p1',
        sprintId: 's1',
        status: TaskStatus.todo,
        priority: TaskPriority.normal,
        assigneeIds: ['m5'],
        dueDate: day(4),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      // ── Hikigai: Design System (Foundations) ──
      Task(
        id: 't6',
        title: 'Define color tokens',
        description: 'Light + dark semantic color scales.',
        projectId: 'p2',
        sprintId: 's2',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        assigneeIds: ['m2', 'me'],
        dueDate: day(-1),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Task(
        id: 't7',
        title: 'Typography scale',
        description: 'Plus Jakarta Sans across all text styles.',
        projectId: 'p2',
        sprintId: 's2',
        status: TaskStatus.inProgress,
        priority: TaskPriority.normal,
        assigneeIds: ['m2'],
        dueDate: day(3),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 't8',
        title: 'Button component variants',
        description: 'Primary, outline, ghost, sizes, states.',
        projectId: 'p2',
        sprintId: 's2',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        assigneeIds: ['m2', 'm4'],
        dueDate: day(6),
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
      // ── Hikigai: API Platform ──
      Task(
        id: 't9',
        title: 'Auth service endpoints',
        description: 'Login, refresh, logout, session.',
        projectId: 'p3',
        sprintId: null,
        status: TaskStatus.inReview,
        priority: TaskPriority.urgent,
        assigneeIds: ['m3', 'me'],
        dueDate: day(0),
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Task(
        id: 't10',
        title: 'Rate limiting middleware',
        description: 'Per-token sliding window limiter.',
        projectId: 'p3',
        sprintId: null,
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        assigneeIds: ['m3'],
        dueDate: day(5),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 't11',
        title: 'Write integration tests for auth',
        description: 'Cover happy path + edge cases.',
        projectId: 'p3',
        sprintId: null,
        status: TaskStatus.todo,
        priority: TaskPriority.normal,
        assigneeIds: ['m5', 'me'],
        dueDate: day(-1),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  static List<Activity> activities() {
    final now = DateTime.now();
    return [
      // Personal
      Activity(
        id: 'pa1',
        kind: ActivityKind.taskCompleted,
        actorId: 'me',
        text: 'completed',
        taskTitle: 'Connect Stripe test mode',
        projectId: 'pp2',
        taskId: 'pt7',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      Activity(
        id: 'pa2',
        kind: ActivityKind.sprintCreated,
        actorId: 'me',
        text: 'started sprint',
        taskTitle: 'Launch Push',
        projectId: 'pp2',
        timestamp: now.subtract(const Duration(days: 4)),
      ),
      Activity(
        id: 'pa3',
        kind: ActivityKind.taskCreated,
        actorId: 'me',
        text: 'created',
        taskTitle: 'Design landing page',
        projectId: 'pp2',
        taskId: 'pt4',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      // Hikigai
      Activity(
        id: 'a1',
        kind: ActivityKind.taskCompleted,
        actorId: 'm2',
        text: 'completed',
        taskTitle: 'Define color tokens',
        projectId: 'p2',
        taskId: 't6',
        timestamp: now.subtract(const Duration(minutes: 14)),
      ),
      Activity(
        id: 'a2',
        kind: ActivityKind.statusChanged,
        actorId: 'm3',
        text: 'moved to In Review',
        taskTitle: 'Auth service endpoints',
        projectId: 'p3',
        taskId: 't9',
        timestamp: now.subtract(const Duration(minutes: 52)),
      ),
      Activity(
        id: 'a3',
        kind: ActivityKind.taskAssigned,
        actorId: 'm2',
        text: 'assigned you to',
        taskTitle: 'Google SSO integration',
        projectId: 'p1',
        taskId: 't3',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      Activity(
        id: 'a3b',
        kind: ActivityKind.taskCreated,
        actorId: 'm3',
        text: 'created',
        taskTitle: 'Google SSO integration',
        projectId: 'p1',
        taskId: 't3',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      Activity(
        id: 'a4',
        kind: ActivityKind.taskCreated,
        actorId: 'm5',
        text: 'created',
        taskTitle: 'Push notification setup',
        projectId: 'p1',
        taskId: 't5',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
