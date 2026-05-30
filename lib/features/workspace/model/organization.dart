import 'package:flutter/material.dart';

/// Top-level tenant. "Personal" is your own org (just you); a company like
/// "Hikigai" is a team org you're invited to. Workspaces live inside an org.
enum OrgType {
  personal,
  team;

  String get label => switch (this) {
        OrgType.personal => 'Personal',
        OrgType.team => 'Team',
      };

  bool get isPersonal => this == OrgType.personal;
}

class Organization {
  final String id;
  final String name;
  final OrgType type;
  final Color color;
  final IconData icon;
  final List<String> memberIds;

  const Organization({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    required this.memberIds,
  });

  bool get isPersonal => type.isPersonal;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Organization copyWith({
    String? name,
    OrgType? type,
    Color? color,
    IconData? icon,
    List<String>? memberIds,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}
