import 'package:flutter_bloc/flutter_bloc.dart';

/// User customization for the side navigation. In-memory for now (mirrors the
/// app's no-backend state); persists naturally once a backend/profile store
/// lands.
class SidebarState {
  final bool showSpaces;
  final bool showRecents;
  final bool showCounts;
  final Set<String> favoriteWorkspaceIds;

  const SidebarState({
    this.showSpaces = true,
    this.showRecents = true,
    this.showCounts = true,
    this.favoriteWorkspaceIds = const {},
  });

  SidebarState copyWith({
    bool? showSpaces,
    bool? showRecents,
    bool? showCounts,
    Set<String>? favoriteWorkspaceIds,
  }) {
    return SidebarState(
      showSpaces: showSpaces ?? this.showSpaces,
      showRecents: showRecents ?? this.showRecents,
      showCounts: showCounts ?? this.showCounts,
      favoriteWorkspaceIds: favoriteWorkspaceIds ?? this.favoriteWorkspaceIds,
    );
  }
}

class SidebarCubit extends Cubit<SidebarState> {
  SidebarCubit() : super(const SidebarState());

  void setShowSpaces(bool v) => emit(state.copyWith(showSpaces: v));
  void setShowRecents(bool v) => emit(state.copyWith(showRecents: v));
  void setShowCounts(bool v) => emit(state.copyWith(showCounts: v));

  void toggleFavorite(String workspaceId) {
    final next = {...state.favoriteWorkspaceIds};
    if (!next.remove(workspaceId)) next.add(workspaceId);
    emit(state.copyWith(favoriteWorkspaceIds: next));
  }

  bool isFavorite(String workspaceId) =>
      state.favoriteWorkspaceIds.contains(workspaceId);
}
