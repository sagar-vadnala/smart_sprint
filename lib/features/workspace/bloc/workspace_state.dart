import 'package:smart_sprint/features/workspace/model/activity.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/organization.dart';
import 'package:smart_sprint/features/workspace/model/project.dart';
import 'package:smart_sprint/features/workspace/model/sprint.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'package:smart_sprint/features/workspace/model/team_member.dart';

/// Holds the full dataset (the `all*` fields) but exposes data scoped to the
/// [currentOrganization]. Screens read the scoped getters (`projects`, `tasks`,
/// `members`, ...) and automatically follow organization switches.
///
/// Note: a `Project` is presented as a "Workspace" in the UI.
class WorkspaceState {
  final List<Organization> organizations;
  final String currentOrganizationId;
  final List<TeamMember> allMembers;
  final List<Project> allProjects;
  final List<Sprint> allSprints;
  final List<Task> allTasks;
  final List<Activity> allActivities;
  final String currentUserId;
  final bool loaded;

  /// Most-recently opened workspace (Project) ids, newest first. Powers the
  /// "Quick access" breadcrumb section.
  final List<String> recentWorkspaceIds;

  const WorkspaceState({
    required this.organizations,
    required this.currentOrganizationId,
    required this.allMembers,
    required this.allProjects,
    required this.allSprints,
    required this.allTasks,
    required this.allActivities,
    required this.currentUserId,
    required this.loaded,
    this.recentWorkspaceIds = const [],
  });

  const WorkspaceState.empty()
    : organizations = const [],
      currentOrganizationId = '',
      allMembers = const [],
      allProjects = const [],
      allSprints = const [],
      allTasks = const [],
      allActivities = const [],
      currentUserId = 'me',
      loaded = false,
      recentWorkspaceIds = const [];

  WorkspaceState copyWith({
    List<Organization>? organizations,
    String? currentOrganizationId,
    List<TeamMember>? allMembers,
    List<Project>? allProjects,
    List<Sprint>? allSprints,
    List<Task>? allTasks,
    List<Activity>? allActivities,
    String? currentUserId,
    bool? loaded,
    List<String>? recentWorkspaceIds,
  }) {
    return WorkspaceState(
      organizations: organizations ?? this.organizations,
      currentOrganizationId:
          currentOrganizationId ?? this.currentOrganizationId,
      allMembers: allMembers ?? this.allMembers,
      allProjects: allProjects ?? this.allProjects,
      allSprints: allSprints ?? this.allSprints,
      allTasks: allTasks ?? this.allTasks,
      allActivities: allActivities ?? this.allActivities,
      currentUserId: currentUserId ?? this.currentUserId,
      loaded: loaded ?? this.loaded,
      recentWorkspaceIds: recentWorkspaceIds ?? this.recentWorkspaceIds,
    );
  }

  /// Recent workspaces scoped to the current organization (most recent first).
  List<Project> get recentWorkspaces => recentWorkspaceIds
      .map(projectById)
      .whereType<Project>()
      .where((p) => p.organizationId == currentOrganizationId)
      .toList();

  /// The active sprint for a workspace, if any.
  Sprint? activeSprintForProject(String projectId) {
    for (final s in sprintsForProject(projectId)) {
      if (s.status == SprintStatus.active) return s;
    }
    return null;
  }

  // ── Current organization ────────────────────────────────────────────────────

  Organization get currentOrganization => organizations.firstWhere(
    (o) => o.id == currentOrganizationId,
    orElse: () => organizations.first,
  );

  bool get isPersonal => currentOrganization.isPersonal;

  Set<String> get _projectIdsInOrg => allProjects
      .where((p) => p.organizationId == currentOrganizationId)
      .map((p) => p.id)
      .toSet();

  // ── Scoped collections (what screens read) ──────────────────────────────────

  /// Workspaces (the [Project] class) in the current organization.
  List<Project> get projects => allProjects
      .where((p) => p.organizationId == currentOrganizationId)
      .toList();

  List<TeamMember> get members => currentOrganization.memberIds
      .map(memberById)
      .whereType<TeamMember>()
      .toList();

  List<Sprint> get sprints {
    final ids = _projectIdsInOrg;
    return allSprints.where((s) => ids.contains(s.projectId)).toList();
  }

  List<Task> get tasks {
    final ids = _projectIdsInOrg;
    return allTasks.where((t) => ids.contains(t.projectId)).toList();
  }

  List<Activity> get activities {
    final ids = _projectIdsInOrg;
    return allActivities
        .where((a) => a.projectId == null || ids.contains(a.projectId))
        .toList();
  }

  // ── Lookups (search the master lists) ───────────────────────────────────────

  TeamMember? memberById(String id) {
    for (final m in allMembers) {
      if (m.id == id) return m;
    }
    return null;
  }

  Project? projectById(String id) {
    for (final p in allProjects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Sprint? sprintById(String? id) {
    if (id == null) return null;
    for (final s in allSprints) {
      if (s.id == id) return s;
    }
    return null;
  }

  TeamMember get currentUser => memberById(currentUserId) ?? allMembers.first;

  List<TeamMember> membersFor(Iterable<String> ids) =>
      ids.map(memberById).whereType<TeamMember>().toList();

  // ── Task views (scoped to current organization) ─────────────────────────────

  List<Task> get myTasks =>
      tasks.where((t) => t.assigneeIds.contains(currentUserId)).toList();

  List<Task> get myOpenTasks => myTasks.where((t) => !t.isDone).toList();

  List<Task> tasksForProject(String projectId) =>
      allTasks.where((t) => t.projectId == projectId).toList();

  List<Task> tasksForSprint(String sprintId) =>
      allTasks.where((t) => t.sprintId == sprintId).toList();

  List<Task> tasksByStatus(List<Task> source, TaskStatus status) =>
      source.where((t) => t.status == status).toList();

  List<Sprint> sprintsForProject(String projectId) =>
      allSprints.where((s) => s.projectId == projectId).toList();

  // ── Dashboard counters ──────────────────────────────────────────────────────

  int get myDueTodayCount => myOpenTasks.where((t) => t.isDueToday).length;

  int get myOverdueCount => myOpenTasks.where((t) => t.isOverdue).length;

  int get myInReviewCount =>
      myTasks.where((t) => t.status == TaskStatus.inReview).length;

  int get myDoneCount => myTasks.where((t) => t.isDone).length;

  double projectProgress(String projectId) {
    final list = tasksForProject(projectId);
    if (list.isEmpty) return 0;
    final done = list.where((t) => t.isDone).length;
    return done / list.length;
  }
}
