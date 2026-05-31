import 'package:smart_sprint/core/api/api_client.dart';
import 'package:smart_sprint/features/workspace/model/activity.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/organization.dart';
import 'package:smart_sprint/features/workspace/model/project.dart';
import 'package:smart_sprint/features/workspace/model/sprint.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'package:smart_sprint/features/workspace/model/team_member.dart';

/// Everything the app needs on launch, parsed into models.
class BootstrapData {
  final TeamMember currentUser;
  final List<Organization> organizations;
  final List<TeamMember> members;
  final List<Project> workspaces;
  final List<Sprint> sprints;
  final List<Task> tasks;
  final List<Activity> activities;

  const BootstrapData({
    required this.currentUser,
    required this.organizations,
    required this.members,
    required this.workspaces,
    required this.sprints,
    required this.tasks,
    required this.activities,
  });
}

/// All workspace/org/task network calls. Returns parsed models so the bloc
/// never touches raw JSON.
class WorkspaceRepository {
  final ApiClient _api;

  WorkspaceRepository({ApiClient? api}) : _api = api ?? ApiClient();

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<BootstrapData> bootstrap() async {
    final json = await _api.get('/bootstrap');
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) f) =>
        (json[key] as List? ?? [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();

    return BootstrapData(
      currentUser: TeamMember.fromJson(json['user'] as Map<String, dynamic>),
      organizations: parse('organizations', Organization.fromJson),
      members: parse('members', TeamMember.fromJson),
      workspaces: parse('workspaces', Project.fromJson),
      sprints: parse('sprints', Sprint.fromJson),
      tasks: parse('tasks', Task.fromJson),
      activities: parse('activities', Activity.fromJson),
    );
  }

  // ── Organizations ─────────────────────────────────────────────────────────

  Future<Organization> createOrganization({
    required String name,
    required OrgType type,
    required int color,
    required String iconKey,
  }) async {
    final json = await _api.post(
      '/organizations',
      data: {'name': name, 'type': type.name, 'color': color, 'icon': iconKey},
    );
    return Organization.fromJson(json);
  }

  /// Invite an existing user (by email) into a team org. Returns the org's
  /// full member list. Throws [ApiException] (e.g. "No user with that email").
  Future<List<TeamMember>> addMember(String orgId, String email) async {
    // `_api.post` unwraps a JSON array into {'data': [...]} and turns any
    // 4xx error body into a readable ApiException.
    final body = await _api.post(
      '/organizations/$orgId/members',
      data: {'email': email},
    );
    final list = (body['data'] as List)
        .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  // ── Workspaces ──────────────────────────────────────────────────────────────

  Future<Project> createWorkspace({
    required String organizationId,
    required String name,
    required String description,
    required int color,
    required String iconKey,
  }) async {
    final json = await _api.post(
      '/workspaces',
      data: {
        'organizationId': organizationId,
        'name': name,
        'description': description,
        'color': color,
        'icon': iconKey,
      },
    );
    return Project.fromJson(json);
  }

  // ── Sprints ───────────────────────────────────────────────────────────────

  Future<Sprint> createSprint({
    required String projectId,
    required String name,
    required String goal,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final json = await _api.post(
      '/sprints',
      data: {
        'projectId': projectId,
        'name': name,
        'goal': goal,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    return Sprint.fromJson(json);
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Future<Task> createTask({
    required String projectId,
    String? sprintId,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    required List<String> assigneeIds,
    DateTime? dueDate,
  }) async {
    final json = await _api.post(
      '/tasks',
      data: {
        'projectId': projectId,
        'sprintId': sprintId,
        'title': title,
        'description': description,
        'status': status.name,
        'priority': priority.name,
        'assigneeIds': assigneeIds,
        'dueDate': dueDate?.toIso8601String(),
      },
    );
    return Task.fromJson(json);
  }

  /// Generic task patch. Pass only the fields that changed.
  Future<Task> updateTask(
    String taskId, {
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? sprintId,
    bool clearSprint = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    List<String>? assigneeIds,
    String? workspaceId,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status.name;
    if (priority != null) body['priority'] = priority.name;
    if (clearSprint) {
      body['clearSprint'] = true;
    } else if (sprintId != null) {
      body['sprintId'] = sprintId;
    }
    if (clearDueDate) {
      body['clearDueDate'] = true;
    } else if (dueDate != null) {
      body['dueDate'] = dueDate.toIso8601String();
    }
    if (assigneeIds != null) body['assigneeIds'] = assigneeIds;
    if (workspaceId != null) body['workspaceId'] = workspaceId;

    final json = await _api.raw.patch('/tasks/$taskId', data: body);
    return Task.fromJson(json.data as Map<String, dynamic>);
  }

  Future<void> deleteTask(String taskId) async {
    await _api.raw.delete('/tasks/$taskId');
  }

  Future<Task> duplicateTask(String taskId) async {
    final json = await _api.post('/tasks/$taskId/duplicate');
    return Task.fromJson(json);
  }

  // ── SubTasks (each returns the updated parent task) ─────────────────────────

  Future<Task> addSubtask(
    String taskId,
    String title, {
    String? parentSubTaskId,
  }) async {
    final json = await _api.post(
      '/tasks/$taskId/subtasks',
      data: {'title': title, 'parentSubTaskId': parentSubTaskId},
    );
    return Task.fromJson(json);
  }

  Future<Task> updateSubtask(
    String taskId,
    String subTaskId, {
    String? title,
    TaskStatus? status,
    TaskPriority? priority,
    bool clearPriority = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    List<String>? assigneeIds,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (status != null) body['status'] = status.name;
    if (clearPriority) {
      body['clearPriority'] = true;
    } else if (priority != null) {
      body['priority'] = priority.name;
    }
    if (clearDueDate) {
      body['clearDueDate'] = true;
    } else if (dueDate != null) {
      body['dueDate'] = dueDate.toIso8601String();
    }
    if (assigneeIds != null) body['assigneeIds'] = assigneeIds;

    final json = await _api.raw.patch(
      '/tasks/$taskId/subtasks/$subTaskId',
      data: body,
    );
    return Task.fromJson(json.data as Map<String, dynamic>);
  }

  Future<Task> deleteSubtask(String taskId, String subTaskId) async {
    final json = await _api.raw.delete('/tasks/$taskId/subtasks/$subTaskId');
    return Task.fromJson(json.data as Map<String, dynamic>);
  }

  // ── Comments → activity ─────────────────────────────────────────────────────

  Future<Activity> addComment(String taskId, String body) async {
    final json = await _api.post(
      '/tasks/$taskId/comments',
      data: {'body': body},
    );
    return Activity.fromJson(json);
  }
}
