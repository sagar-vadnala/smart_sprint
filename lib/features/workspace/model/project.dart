import 'package:flutter/material.dart';
import 'package:smart_sprint/features/workspace/data/json_mappers.dart';

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

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      color: colorFromInt(json['color'] as int?),
      icon: iconFromKey(json['icon'] as String?),
      memberIds:
          (json['memberIds'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }

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
