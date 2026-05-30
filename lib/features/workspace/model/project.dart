import 'package:flutter/material.dart';

/// Internally `Project`, but presented as a "Workspace" in the UI — the
/// container that lives inside an [Organization] and holds sprints + tasks.
class Project {
  final String id;
  final String organizationId;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final List<String> memberIds;

  const Project({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.memberIds,
  });

  Project copyWith({
    String? name,
    String? description,
    Color? color,
    IconData? icon,
    List<String>? memberIds,
  }) {
    return Project(
      id: id,
      organizationId: organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}
