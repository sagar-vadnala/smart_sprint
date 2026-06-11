import 'package:flutter/material.dart';
import 'package:smart_sprint/features/workspace/data/json_mappers.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';

/// Internally `Project`, but presented as a "Workspace" in the UI — the
/// container that lives inside an [Organization] and holds sprints + tasks.
class Project {
  final String id;
  final String organizationId;
  final String name;
  final String description;
  final Color color;
  final IconData icon;

  /// Silhouette of the icon badge (rounded square / circle / square).
  final IconShape shape;

  /// When true, the badge renders the first letter of [name] instead of [icon]
  /// (ClickUp-style letter avatar).
  final bool useLetter;
  final List<String> memberIds;

  const Project({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.memberIds,
    this.shape = IconShape.roundedSquare,
    this.useLetter = false,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final decoded = workspaceIconFromKey(json['icon'] as String?);
    return Project(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      color: colorFromInt(json['color'] as int?),
      icon: decoded.icon,
      shape: decoded.shape,
      useLetter: decoded.useLetter,
      memberIds:
          (json['memberIds'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Project copyWith({
    String? name,
    String? description,
    Color? color,
    IconData? icon,
    IconShape? shape,
    bool? useLetter,
    List<String>? memberIds,
  }) {
    return Project(
      id: id,
      organizationId: organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      shape: shape ?? this.shape,
      useLetter: useLetter ?? this.useLetter,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}
