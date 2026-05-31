import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_sprint/features/workspace/data/json_mappers.dart';
import 'package:smart_sprint/features/workspace/data/workspace_repository.dart';
import 'package:smart_sprint/features/workspace/model/activity.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/subtask.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'workspace_event.dart';
import 'workspace_state.dart';

/// Backend-backed workspace store.
///
/// Strategy:
///  • **Create** events `await` the API and apply the server object, so ids are
///    always the real server ids (no optimistic-id drift).
///  • **Edit / delete / toggle** events update local state optimistically for a
///    snappy UI, then write through to the API. On a write failure we silently
///    re-bootstrap so the client reconciles with the server.
class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final WorkspaceRepository _repo;

  WorkspaceBloc({WorkspaceRepository? repository})
    : _repo = repository ?? WorkspaceRepository(),
      super(const WorkspaceState.empty()) {
    on<WorkspaceLoaded>(_onLoaded);
    on<OrganizationSwitched>(_onOrganizationSwitched);
    on<OrganizationCreated>(_onOrganizationCreated);
    on<OrgMembersUpdated>(_onOrgMembersUpdated);
    on<WorkspaceOpened>(_onWorkspaceOpened);
    on<TaskCreated>(_onTaskCreated);
    on<TaskStatusChanged>(_onTaskStatusChanged);
    on<TaskAssigneesChanged>(_onTaskAssigneesChanged);
    on<TaskPriorityChanged>(_onTaskPriorityChanged);
    on<TaskDueDateChanged>(_onTaskDueDateChanged);
    on<TaskTitleChanged>(_onTaskTitleChanged);
    on<TaskDescriptionChanged>(_onTaskDescriptionChanged);
    on<TaskToggledDone>(_onTaskToggledDone);
    on<TaskDeleted>(_onTaskDeleted);
    on<TaskMovedToProject>(_onTaskMovedToProject);
    on<TaskMovedToSprint>(_onTaskMovedToSprint);
    on<TaskDuplicated>(_onTaskDuplicated);
    on<CommentAdded>(_onCommentAdded);
    on<SubTaskAdded>(_onSubTaskAdded);
    on<SubTaskToggled>(_onSubTaskToggled);
    on<SubTaskStatusChanged>(_onSubTaskStatusChanged);
    on<SubTaskAssigneesChanged>(_onSubTaskAssigneesChanged);
    on<SubTaskTitleChanged>(_onSubTaskTitleChanged);
    on<SubTaskPriorityChanged>(_onSubTaskPriorityChanged);
    on<SubTaskDueDateChanged>(_onSubTaskDueDateChanged);
    on<SubTaskDeleted>(_onSubTaskDeleted);
    on<SprintCreated>(_onSprintCreated);
    on<ProjectCreated>(_onProjectCreated);
  }

  int _seq = 0;
  String _localId(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> _onLoaded(
    WorkspaceLoaded event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      final data = await _repo.bootstrap();
      emit(_stateFrom(data));
    } catch (_) {
      // Surface an empty-but-loaded state so the app is usable; the user can
      // pull to refresh / retry by reopening.
      emit(state.copyWith(loaded: true));
    }
  }

  WorkspaceState _stateFrom(BootstrapData data) {
    // Prefer the Personal org as the landing org.
    final personal = data.organizations.where((o) => o.isPersonal).firstOrNull;
    final currentOrgId =
        personal?.id ??
        (data.organizations.isNotEmpty ? data.organizations.first.id : '');

    final members = [...data.members];
    if (members.every((m) => m.id != data.currentUser.id)) {
      members.add(data.currentUser);
    }

    return WorkspaceState(
      organizations: data.organizations,
      currentOrganizationId: currentOrgId,
      allMembers: members,
      allProjects: data.workspaces,
      allSprints: data.sprints,
      allTasks: data.tasks,
      allActivities: data.activities,
      currentUserId: data.currentUser.id,
      loaded: true,
    );
  }

  Future<void> _resync(Emitter<WorkspaceState> emit) async {
    try {
      final data = await _repo.bootstrap();
      emit(
        _stateFrom(data).copyWith(
          currentOrganizationId: state.currentOrganizationId,
          recentWorkspaceIds: state.recentWorkspaceIds,
        ),
      );
    } catch (_) {
      // keep current state
    }
  }

  // ── Local-only navigation state ─────────────────────────────────────────────

  void _onOrganizationSwitched(
    OrganizationSwitched event,
    Emitter<WorkspaceState> emit,
  ) {
    if (event.organizationId == state.currentOrganizationId) return;
    emit(state.copyWith(currentOrganizationId: event.organizationId));
  }

  void _onWorkspaceOpened(WorkspaceOpened event, Emitter<WorkspaceState> emit) {
    final next = [
      event.projectId,
      ...state.recentWorkspaceIds.where((id) => id != event.projectId),
    ].take(6).toList();
    emit(state.copyWith(recentWorkspaceIds: next));
  }

  void _onOrgMembersUpdated(
    OrgMembersUpdated event,
    Emitter<WorkspaceState> emit,
  ) {
    // Merge the refreshed members into the global member pool (by id)...
    final byId = {for (final m in state.allMembers) m.id: m};
    for (final m in event.members) {
      byId[m.id] = m;
    }
    // ...and update the org's memberIds.
    final orgs = state.organizations
        .map(
          (o) => o.id == event.organizationId
              ? o.copyWith(memberIds: event.members.map((m) => m.id).toList())
              : o,
        )
        .toList();
    emit(state.copyWith(allMembers: byId.values.toList(), organizations: orgs));
  }

  // ── Optimistic-activity helper (replaced by server truth on next bootstrap) ──

  Activity _activity(
    ActivityKind kind,
    String text, {
    String? taskTitle,
    String? projectId,
    String? taskId,
    String? body,
  }) {
    return Activity(
      id: _localId('a'),
      kind: kind,
      actorId: state.currentUserId,
      text: text,
      taskTitle: taskTitle,
      projectId: projectId,
      taskId: taskId,
      body: body,
      timestamp: DateTime.now(),
    );
  }

  List<Activity> _prepend(Activity a) => [a, ...state.allActivities];

  List<Task> _replaceTask(Task task) =>
      state.allTasks.map((t) => t.id == task.id ? task : t).toList();

  // ── Create (server-authoritative) ───────────────────────────────────────────

  Future<void> _onOrganizationCreated(
    OrganizationCreated event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      final org = await _repo.createOrganization(
        name: event.name,
        type: event.type,
        color: colorToInt(event.color),
        iconKey: iconKeyFor(event.icon),
      );
      emit(
        state.copyWith(
          organizations: [...state.organizations, org],
          currentOrganizationId: org.id,
        ),
      );
    } catch (_) {
      await _resync(emit);
    }
  }

  Future<void> _onProjectCreated(
    ProjectCreated event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      final project = await _repo.createWorkspace(
        organizationId: state.currentOrganizationId,
        name: event.name,
        description: event.description,
        color: colorToInt(event.color),
        iconKey: iconKeyFor(event.icon),
      );
      emit(
        state.copyWith(
          allProjects: [...state.allProjects, project],
          allActivities: _prepend(
            _activity(
              ActivityKind.projectCreated,
              'created workspace',
              taskTitle: project.name,
              projectId: project.id,
            ),
          ),
        ),
      );
    } catch (_) {
      await _resync(emit);
    }
  }

  Future<void> _onSprintCreated(
    SprintCreated event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      final sprint = await _repo.createSprint(
        projectId: event.projectId,
        name: event.name,
        goal: event.goal,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(
        state.copyWith(
          allSprints: [...state.allSprints, sprint],
          allActivities: _prepend(
            _activity(
              ActivityKind.sprintCreated,
              'created sprint',
              taskTitle: sprint.name,
              projectId: sprint.projectId,
            ),
          ),
        ),
      );
    } catch (_) {
      await _resync(emit);
    }
  }

  Future<void> _onTaskCreated(
    TaskCreated event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      final task = await _repo.createTask(
        projectId: event.projectId,
        sprintId: event.sprintId,
        title: event.title,
        description: event.description,
        status: event.status,
        priority: event.priority,
        assigneeIds: event.assigneeIds,
        dueDate: event.dueDate,
      );
      emit(
        state.copyWith(
          allTasks: [...state.allTasks, task],
          allActivities: _prepend(
            _activity(
              ActivityKind.taskCreated,
              'created',
              taskTitle: task.title,
              projectId: task.projectId,
              taskId: task.id,
            ),
          ),
        ),
      );
    } catch (_) {
      await _resync(emit);
    }
  }

  Future<void> _onTaskDuplicated(
    TaskDuplicated event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      final copy = await _repo.duplicateTask(event.taskId);
      emit(
        state.copyWith(
          allTasks: [...state.allTasks, copy],
          allActivities: _prepend(
            _activity(
              ActivityKind.taskCreated,
              'duplicated',
              taskTitle: copy.title,
              projectId: copy.projectId,
              taskId: copy.id,
            ),
          ),
        ),
      );
    } catch (_) {
      await _resync(emit);
    }
  }

  Future<void> _onSubTaskAdded(
    SubTaskAdded event,
    Emitter<WorkspaceState> emit,
  ) async {
    final title = event.title.trim();
    if (title.isEmpty) return;
    try {
      final task = await _repo.addSubtask(
        event.taskId,
        title,
        parentSubTaskId: event.parentSubTaskId,
      );
      emit(state.copyWith(allTasks: _replaceTask(task)));
    } catch (_) {
      await _resync(emit);
    }
  }

  // ── Edit / delete (optimistic + write-through) ──────────────────────────────

  /// Applies [transform] locally, emits, then runs [write]; on failure resyncs.
  Future<void> _editTask(
    Emitter<WorkspaceState> emit,
    String taskId,
    Task Function(Task) transform,
    Future<void> Function() write, {
    Activity? activity,
  }) async {
    final exists = state.allTasks.any((t) => t.id == taskId);
    if (!exists) return;
    final updated = state.allTasks
        .map((t) => t.id == taskId ? transform(t) : t)
        .toList();
    emit(
      state.copyWith(
        allTasks: updated,
        allActivities: activity != null ? _prepend(activity) : null,
      ),
    );
    try {
      await write();
    } catch (_) {
      await _resync(emit);
    }
  }

  Future<void> _onTaskStatusChanged(
    TaskStatusChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null) return;
    final isDone = event.status == TaskStatus.done;
    await _editTask(
      emit,
      event.taskId,
      (t) => t.copyWith(status: event.status),
      () => _repo.updateTask(event.taskId, status: event.status),
      activity: _activity(
        isDone ? ActivityKind.taskCompleted : ActivityKind.statusChanged,
        isDone ? 'completed' : 'moved to ${event.status.label}',
        taskTitle: task.title,
        projectId: task.projectId,
        taskId: task.id,
      ),
    );
  }

  Future<void> _onTaskToggledDone(
    TaskToggledDone event,
    Emitter<WorkspaceState> emit,
  ) async {
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null) return;
    final next = task.isDone ? TaskStatus.todo : TaskStatus.done;
    await _editTask(
      emit,
      event.taskId,
      (t) => t.copyWith(status: next),
      () => _repo.updateTask(event.taskId, status: next),
      activity: next == TaskStatus.done
          ? _activity(
              ActivityKind.taskCompleted,
              'completed',
              taskTitle: task.title,
              projectId: task.projectId,
              taskId: task.id,
            )
          : null,
    );
  }

  Future<void> _onTaskAssigneesChanged(
    TaskAssigneesChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null) return;
    await _editTask(
      emit,
      event.taskId,
      (t) => t.copyWith(assigneeIds: event.assigneeIds),
      () => _repo.updateTask(event.taskId, assigneeIds: event.assigneeIds),
      activity: _activity(
        ActivityKind.taskAssigned,
        'updated assignees on',
        taskTitle: task.title,
        projectId: task.projectId,
        taskId: task.id,
      ),
    );
  }

  Future<void> _onTaskPriorityChanged(
    TaskPriorityChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    await _editTask(
      emit,
      event.taskId,
      (t) => t.copyWith(priority: event.priority),
      () => _repo.updateTask(event.taskId, priority: event.priority),
    );
  }

  Future<void> _onTaskDueDateChanged(
    TaskDueDateChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    await _editTask(
      emit,
      event.taskId,
      (t) => event.dueDate == null
          ? t.copyWith(clearDueDate: true)
          : t.copyWith(dueDate: event.dueDate),
      () => _repo.updateTask(
        event.taskId,
        dueDate: event.dueDate,
        clearDueDate: event.dueDate == null,
      ),
    );
  }

  Future<void> _onTaskTitleChanged(
    TaskTitleChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    final title = event.title.trim();
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null || title.isEmpty || task.title == title) return;
    await _editTask(
      emit,
      event.taskId,
      (t) => t.copyWith(title: title),
      () => _repo.updateTask(event.taskId, title: title),
      activity: _activity(
        ActivityKind.edited,
        'renamed this task',
        projectId: task.projectId,
        taskId: task.id,
      ),
    );
  }

  Future<void> _onTaskDescriptionChanged(
    TaskDescriptionChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null || task.description == event.description) return;
    await _editTask(
      emit,
      event.taskId,
      (t) => t.copyWith(description: event.description),
      () => _repo.updateTask(event.taskId, description: event.description),
      activity: _activity(
        ActivityKind.edited,
        'updated the description',
        projectId: task.projectId,
        taskId: task.id,
      ),
    );
  }

  Future<void> _onTaskMovedToProject(
    TaskMovedToProject event,
    Emitter<WorkspaceState> emit,
  ) async {
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null || task.projectId == event.newProjectId) return;
    await _editTask(
      emit,
      event.taskId,
      (t) => t.copyWith(projectId: event.newProjectId, clearSprint: true),
      () => _repo.updateTask(event.taskId, workspaceId: event.newProjectId),
      activity: _activity(
        ActivityKind.edited,
        'moved this task',
        taskTitle: task.title,
        projectId: event.newProjectId,
        taskId: task.id,
      ),
    );
  }

  Future<void> _onTaskMovedToSprint(
    TaskMovedToSprint event,
    Emitter<WorkspaceState> emit,
  ) async {
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null || task.sprintId == event.sprintId) return;
    final sprintName = state.sprintById(event.sprintId)?.name ?? 'backlog';
    await _editTask(
      emit,
      event.taskId,
      (t) => event.sprintId == null
          ? t.copyWith(clearSprint: true)
          : t.copyWith(sprintId: event.sprintId),
      () => _repo.updateTask(
        event.taskId,
        sprintId: event.sprintId,
        clearSprint: event.sprintId == null,
      ),
      activity: _activity(
        ActivityKind.edited,
        'moved to $sprintName',
        taskTitle: task.title,
        projectId: task.projectId,
        taskId: task.id,
      ),
    );
  }

  Future<void> _onTaskDeleted(
    TaskDeleted event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(
      state.copyWith(
        allTasks: state.allTasks.where((t) => t.id != event.taskId).toList(),
      ),
    );
    try {
      await _repo.deleteTask(event.taskId);
    } catch (_) {
      await _resync(emit);
    }
  }

  Future<void> _onCommentAdded(
    CommentAdded event,
    Emitter<WorkspaceState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    // Optimistic comment for instant feedback.
    emit(
      state.copyWith(
        allActivities: _prepend(
          _activity(
            ActivityKind.comment,
            'commented',
            taskTitle: task?.title,
            projectId: task?.projectId,
            taskId: event.taskId,
            body: text,
          ),
        ),
      ),
    );
    try {
      await _repo.addComment(event.taskId, text);
    } catch (_) {
      await _resync(emit);
    }
  }

  // ── SubTask edits (write-through; server returns the updated parent task) ────

  Future<void> _editSubtask(
    Emitter<WorkspaceState> emit,
    String taskId,
    SubTask Function(SubTask) transform,
    Future<Task> Function() write,
  ) async {
    final updated = state.allTasks.map((t) {
      if (t.id != taskId) return t;
      return t.copyWith(subtasks: _mapSubtaskById(t.subtasks, transform));
    }).toList();
    emit(state.copyWith(allTasks: updated));
    try {
      final task = await write();
      emit(state.copyWith(allTasks: _replaceTask(task)));
    } catch (_) {
      await _resync(emit);
    }
  }

  Future<void> _onSubTaskToggled(
    SubTaskToggled event,
    Emitter<WorkspaceState> emit,
  ) async {
    final current = _findSubtask(event.taskId, event.subTaskId);
    if (current == null) return;
    final next = current.isDone ? TaskStatus.todo : TaskStatus.done;
    await _editSubtask(
      emit,
      event.taskId,
      (s) => s.id == event.subTaskId ? s.copyWith(status: next) : s,
      () => _repo.updateSubtask(event.taskId, event.subTaskId, status: next),
    );
  }

  Future<void> _onSubTaskStatusChanged(
    SubTaskStatusChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    await _editSubtask(
      emit,
      event.taskId,
      (s) => s.id == event.subTaskId ? s.copyWith(status: event.status) : s,
      () => _repo.updateSubtask(
        event.taskId,
        event.subTaskId,
        status: event.status,
      ),
    );
  }

  Future<void> _onSubTaskAssigneesChanged(
    SubTaskAssigneesChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    await _editSubtask(
      emit,
      event.taskId,
      (s) => s.id == event.subTaskId
          ? s.copyWith(assigneeIds: event.assigneeIds)
          : s,
      () => _repo.updateSubtask(
        event.taskId,
        event.subTaskId,
        assigneeIds: event.assigneeIds,
      ),
    );
  }

  Future<void> _onSubTaskTitleChanged(
    SubTaskTitleChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    final title = event.title.trim();
    if (title.isEmpty) return;
    await _editSubtask(
      emit,
      event.taskId,
      (s) => s.id == event.subTaskId ? s.copyWith(title: title) : s,
      () => _repo.updateSubtask(event.taskId, event.subTaskId, title: title),
    );
  }

  Future<void> _onSubTaskPriorityChanged(
    SubTaskPriorityChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    await _editSubtask(
      emit,
      event.taskId,
      (s) => s.id == event.subTaskId
          ? (event.priority == null
                ? s.copyWith(clearPriority: true)
                : s.copyWith(priority: event.priority))
          : s,
      () => _repo.updateSubtask(
        event.taskId,
        event.subTaskId,
        priority: event.priority,
        clearPriority: event.priority == null,
      ),
    );
  }

  Future<void> _onSubTaskDueDateChanged(
    SubTaskDueDateChanged event,
    Emitter<WorkspaceState> emit,
  ) async {
    await _editSubtask(
      emit,
      event.taskId,
      (s) => s.id == event.subTaskId
          ? (event.dueDate == null
                ? s.copyWith(clearDueDate: true)
                : s.copyWith(dueDate: event.dueDate))
          : s,
      () => _repo.updateSubtask(
        event.taskId,
        event.subTaskId,
        dueDate: event.dueDate,
        clearDueDate: event.dueDate == null,
      ),
    );
  }

  Future<void> _onSubTaskDeleted(
    SubTaskDeleted event,
    Emitter<WorkspaceState> emit,
  ) async {
    final updated = state.allTasks.map((t) {
      if (t.id != event.taskId) return t;
      return t.copyWith(
        subtasks: _removeSubtaskById(t.subtasks, event.subTaskId),
      );
    }).toList();
    emit(state.copyWith(allTasks: updated));
    try {
      final task = await _repo.deleteSubtask(event.taskId, event.subTaskId);
      emit(state.copyWith(allTasks: _replaceTask(task)));
    } catch (_) {
      await _resync(emit);
    }
  }

  // ── Recursive subtask helpers (operate at any depth) ────────────────────────

  SubTask? _findSubtask(String taskId, String subId) {
    final task = state.allTasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) return null;
    SubTask? search(List<SubTask> list) {
      for (final s in list) {
        if (s.id == subId) return s;
        final found = search(s.subtasks);
        if (found != null) return found;
      }
      return null;
    }

    return search(task.subtasks);
  }

  static List<SubTask> _mapSubtaskById(
    List<SubTask> list,
    SubTask Function(SubTask) edit,
  ) {
    return list.map((s) {
      final edited = edit(s);
      if (edited.subtasks.isEmpty) return edited;
      return edited.copyWith(subtasks: _mapSubtaskById(edited.subtasks, edit));
    }).toList();
  }

  static List<SubTask> _removeSubtaskById(List<SubTask> list, String id) {
    return list
        .where((s) => s.id != id)
        .map(
          (s) => s.subtasks.isEmpty
              ? s
              : s.copyWith(subtasks: _removeSubtaskById(s.subtasks, id)),
        )
        .toList();
  }
}
