import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_sprint/features/workspace/data/seed_data.dart';
import 'package:smart_sprint/features/workspace/model/activity.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/project.dart';
import 'package:smart_sprint/features/workspace/model/sprint.dart';
import 'package:smart_sprint/features/workspace/model/subtask.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'package:smart_sprint/features/workspace/model/organization.dart';
import 'workspace_event.dart';
import 'workspace_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  WorkspaceBloc() : super(const WorkspaceState.empty()) {
    on<WorkspaceLoaded>(_onLoaded);
    on<OrganizationSwitched>(_onOrganizationSwitched);
    on<OrganizationCreated>(_onOrganizationCreated);
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

  // ── Recursive subtask helpers (operate by id at any depth) ──────────────────

  static List<SubTask> _mapSubtaskById(
    List<SubTask> list,
    String id,
    SubTask Function(SubTask) edit,
  ) {
    return list.map((s) {
      if (s.id == id) return edit(s);
      if (s.subtasks.isEmpty) return s;
      return s.copyWith(subtasks: _mapSubtaskById(s.subtasks, id, edit));
    }).toList();
  }

  static List<SubTask> _addSubtaskUnder(
    List<SubTask> list,
    String parentId,
    SubTask child,
  ) {
    return list.map((s) {
      if (s.id == parentId) {
        return s.copyWith(subtasks: [...s.subtasks, child]);
      }
      if (s.subtasks.isEmpty) return s;
      return s.copyWith(
        subtasks: _addSubtaskUnder(s.subtasks, parentId, child),
      );
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

  int _seq = 0;
  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  void _onLoaded(WorkspaceLoaded event, Emitter<WorkspaceState> emit) {
    emit(
      WorkspaceState(
        organizations: SeedData.organizations,
        currentOrganizationId: SeedData.defaultOrganizationId,
        allMembers: SeedData.members,
        allProjects: SeedData.projects,
        allSprints: SeedData.sprints(),
        allTasks: SeedData.tasks(),
        allActivities: SeedData.activities(),
        currentUserId: SeedData.currentUserId,
        loaded: true,
      ),
    );
  }

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

  void _onOrganizationCreated(
    OrganizationCreated event,
    Emitter<WorkspaceState> emit,
  ) {
    final org = Organization(
      id: _newId('org'),
      name: event.name,
      type: event.type,
      color: event.color,
      icon: event.icon,
      memberIds: [state.currentUserId],
    );
    emit(
      state.copyWith(
        organizations: [...state.organizations, org],
        currentOrganizationId: org.id,
      ),
    );
  }

  Activity _activity(
    ActivityKind kind,
    String text, {
    String? taskTitle,
    String? projectId,
    String? taskId,
    String? body,
  }) {
    return Activity(
      id: _newId('a'),
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

  void _onTaskCreated(TaskCreated event, Emitter<WorkspaceState> emit) {
    final task = Task(
      id: _newId('t'),
      title: event.title,
      description: event.description,
      projectId: event.projectId,
      sprintId: event.sprintId,
      status: event.status,
      priority: event.priority,
      assigneeIds: event.assigneeIds,
      dueDate: event.dueDate,
      createdAt: DateTime.now(),
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
  }

  void _onTaskStatusChanged(
    TaskStatusChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    Task? changed;
    final updated = state.allTasks.map((t) {
      if (t.id == event.taskId) {
        changed = t.copyWith(status: event.status);
        return changed!;
      }
      return t;
    }).toList();

    if (changed == null) return;

    final isDone = event.status == TaskStatus.done;
    emit(
      state.copyWith(
        allTasks: updated,
        allActivities: _prepend(
          _activity(
            isDone ? ActivityKind.taskCompleted : ActivityKind.statusChanged,
            isDone ? 'completed' : 'moved to ${event.status.label}',
            taskTitle: changed!.title,
            projectId: changed!.projectId,
            taskId: changed!.id,
          ),
        ),
      ),
    );
  }

  void _onTaskAssigneesChanged(
    TaskAssigneesChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    Task? changed;
    final updated = state.allTasks.map((t) {
      if (t.id == event.taskId) {
        changed = t.copyWith(assigneeIds: event.assigneeIds);
        return changed!;
      }
      return t;
    }).toList();

    if (changed == null) return;

    emit(
      state.copyWith(
        allTasks: updated,
        allActivities: _prepend(
          _activity(
            ActivityKind.taskAssigned,
            'updated assignees on',
            taskTitle: changed!.title,
            projectId: changed!.projectId,
            taskId: changed!.id,
          ),
        ),
      ),
    );
  }

  void _onTaskPriorityChanged(
    TaskPriorityChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    _updateTask(
      emit,
      event.taskId,
      (t) => t.copyWith(priority: event.priority),
    );
  }

  void _onTaskDueDateChanged(
    TaskDueDateChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    _updateTask(
      emit,
      event.taskId,
      (t) => event.dueDate == null
          ? t.copyWith(clearDueDate: true)
          : t.copyWith(dueDate: event.dueDate),
    );
  }

  void _onCommentAdded(CommentAdded event, Emitter<WorkspaceState> emit) {
    final text = event.text.trim();
    if (text.isEmpty) return;
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
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
  }

  void _onTaskToggledDone(TaskToggledDone event, Emitter<WorkspaceState> emit) {
    Task? changed;
    final updated = state.allTasks.map((t) {
      if (t.id == event.taskId) {
        final next = t.isDone ? TaskStatus.todo : TaskStatus.done;
        changed = t.copyWith(status: next);
        return changed!;
      }
      return t;
    }).toList();

    if (changed == null) return;

    emit(
      state.copyWith(
        allTasks: updated,
        allActivities: changed!.isDone
            ? _prepend(
                _activity(
                  ActivityKind.taskCompleted,
                  'completed',
                  taskTitle: changed!.title,
                  projectId: changed!.projectId,
                  taskId: changed!.id,
                ),
              )
            : state.allActivities,
      ),
    );
  }

  void _onTaskDeleted(TaskDeleted event, Emitter<WorkspaceState> emit) {
    emit(
      state.copyWith(
        allTasks: state.allTasks.where((t) => t.id != event.taskId).toList(),
      ),
    );
  }

  void _onTaskMovedToProject(
    TaskMovedToProject event,
    Emitter<WorkspaceState> emit,
  ) {
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null || task.projectId == event.newProjectId) return;
    _updateTask(
      emit,
      event.taskId,
      // Moving to a different workspace clears the sprint (sprints belong to
      // a specific workspace).
      (t) => t.copyWith(projectId: event.newProjectId, clearSprint: true),
    );
    emit(
      state.copyWith(
        allActivities: _prepend(
          _activity(
            ActivityKind.edited,
            'moved this task',
            taskTitle: task.title,
            projectId: event.newProjectId,
            taskId: task.id,
          ),
        ),
      ),
    );
  }

  void _onTaskMovedToSprint(
    TaskMovedToSprint event,
    Emitter<WorkspaceState> emit,
  ) {
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null || task.sprintId == event.sprintId) return;
    _updateTask(
      emit,
      event.taskId,
      (t) => event.sprintId == null
          ? t.copyWith(clearSprint: true)
          : t.copyWith(sprintId: event.sprintId),
    );
    final sprintName = state.sprintById(event.sprintId)?.name ?? 'backlog';
    emit(
      state.copyWith(
        allActivities: _prepend(
          _activity(
            ActivityKind.edited,
            'moved to $sprintName',
            taskTitle: task.title,
            projectId: task.projectId,
            taskId: task.id,
          ),
        ),
      ),
    );
  }

  void _onTaskDuplicated(TaskDuplicated event, Emitter<WorkspaceState> emit) {
    final source = state.allTasks
        .where((t) => t.id == event.taskId)
        .firstOrNull;
    if (source == null) return;
    final copy = Task(
      id: _newId('t'),
      title: '${source.title} (copy)',
      description: source.description,
      projectId: source.projectId,
      sprintId: source.sprintId,
      status: TaskStatus.todo,
      priority: source.priority,
      assigneeIds: source.assigneeIds,
      dueDate: source.dueDate,
      createdAt: DateTime.now(),
      subtasks: source.subtasks,
    );
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
  }

  void _updateTask(
    Emitter<WorkspaceState> emit,
    String taskId,
    Task Function(Task) transform,
  ) {
    final updated = state.allTasks
        .map((t) => t.id == taskId ? transform(t) : t)
        .toList();
    emit(state.copyWith(allTasks: updated));
  }

  void _onTaskTitleChanged(
    TaskTitleChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    final title = event.title.trim();
    if (title.isEmpty) return;
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null || task.title == title) return;
    _updateTask(emit, event.taskId, (t) => t.copyWith(title: title));
    emit(
      state.copyWith(
        allActivities: _prepend(
          _activity(
            ActivityKind.edited,
            'renamed this task',
            projectId: task.projectId,
            taskId: task.id,
          ),
        ),
      ),
    );
  }

  void _onTaskDescriptionChanged(
    TaskDescriptionChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null || task.description == event.description) return;
    _updateTask(
      emit,
      event.taskId,
      (t) => t.copyWith(description: event.description),
    );
    emit(
      state.copyWith(
        allActivities: _prepend(
          _activity(
            ActivityKind.edited,
            'updated the description',
            projectId: task.projectId,
            taskId: task.id,
          ),
        ),
      ),
    );
  }

  void _onSubTaskAdded(SubTaskAdded event, Emitter<WorkspaceState> emit) {
    final title = event.title.trim();
    if (title.isEmpty) return;
    final task = state.allTasks.where((t) => t.id == event.taskId).firstOrNull;
    if (task == null) return;
    final child = SubTask(id: _newId('st'), title: title);
    final updated = state.allTasks
        .map(
          (t) => t.id == event.taskId
              ? t.copyWith(
                  subtasks: event.parentSubTaskId == null
                      ? [...t.subtasks, child]
                      : _addSubtaskUnder(
                          t.subtasks,
                          event.parentSubTaskId!,
                          child,
                        ),
                )
              : t,
        )
        .toList();
    emit(
      state.copyWith(
        allTasks: updated,
        allActivities: _prepend(
          _activity(
            ActivityKind.taskCreated,
            'created subtask',
            taskTitle: title,
            projectId: task.projectId,
            taskId: task.id,
          ),
        ),
      ),
    );
  }

  void _onSubTaskToggled(SubTaskToggled event, Emitter<WorkspaceState> emit) {
    _updateTask(emit, event.taskId, (t) {
      return t.copyWith(
        subtasks: _mapSubtaskById(
          t.subtasks,
          event.subTaskId,
          (s) =>
              s.copyWith(status: s.isDone ? TaskStatus.todo : TaskStatus.done),
        ),
      );
    });
  }

  void _onSubTaskStatusChanged(
    SubTaskStatusChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    _updateTask(emit, event.taskId, (t) {
      return t.copyWith(
        subtasks: _mapSubtaskById(
          t.subtasks,
          event.subTaskId,
          (s) => s.copyWith(status: event.status),
        ),
      );
    });
  }

  void _onSubTaskAssigneesChanged(
    SubTaskAssigneesChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    _updateTask(emit, event.taskId, (t) {
      return t.copyWith(
        subtasks: _mapSubtaskById(
          t.subtasks,
          event.subTaskId,
          (s) => s.copyWith(assigneeIds: event.assigneeIds),
        ),
      );
    });
  }

  void _onSubTaskTitleChanged(
    SubTaskTitleChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    final title = event.title.trim();
    if (title.isEmpty) return;
    _updateTask(emit, event.taskId, (t) {
      return t.copyWith(
        subtasks: _mapSubtaskById(
          t.subtasks,
          event.subTaskId,
          (s) => s.copyWith(title: title),
        ),
      );
    });
  }

  void _onSubTaskPriorityChanged(
    SubTaskPriorityChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    _updateTask(emit, event.taskId, (t) {
      return t.copyWith(
        subtasks: _mapSubtaskById(
          t.subtasks,
          event.subTaskId,
          (s) => event.priority == null
              ? s.copyWith(clearPriority: true)
              : s.copyWith(priority: event.priority),
        ),
      );
    });
  }

  void _onSubTaskDueDateChanged(
    SubTaskDueDateChanged event,
    Emitter<WorkspaceState> emit,
  ) {
    _updateTask(emit, event.taskId, (t) {
      return t.copyWith(
        subtasks: _mapSubtaskById(
          t.subtasks,
          event.subTaskId,
          (s) => event.dueDate == null
              ? s.copyWith(clearDueDate: true)
              : s.copyWith(dueDate: event.dueDate),
        ),
      );
    });
  }

  void _onSubTaskDeleted(SubTaskDeleted event, Emitter<WorkspaceState> emit) {
    _updateTask(emit, event.taskId, (t) {
      return t.copyWith(
        subtasks: _removeSubtaskById(t.subtasks, event.subTaskId),
      );
    });
  }

  void _onSprintCreated(SprintCreated event, Emitter<WorkspaceState> emit) {
    final sprint = Sprint(
      id: _newId('s'),
      name: event.name,
      goal: event.goal,
      projectId: event.projectId,
      startDate: event.startDate,
      endDate: event.endDate,
      status: SprintStatus.planned,
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
  }

  void _onProjectCreated(ProjectCreated event, Emitter<WorkspaceState> emit) {
    final project = Project(
      id: _newId('p'),
      organizationId: state.currentOrganizationId,
      name: event.name,
      description: event.description,
      color: event.color,
      icon: event.icon,
      memberIds: event.memberIds.isEmpty
          ? [state.currentUserId]
          : event.memberIds,
    );
    emit(
      state.copyWith(
        allProjects: [...state.allProjects, project],
        allActivities: _prepend(
          _activity(
            ActivityKind.projectCreated,
            'created project',
            taskTitle: project.name,
            projectId: project.id,
          ),
        ),
      ),
    );
  }
}
