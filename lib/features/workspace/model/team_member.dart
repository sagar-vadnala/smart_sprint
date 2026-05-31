import 'package:flutter/material.dart';
import 'package:smart_sprint/features/workspace/data/json_mappers.dart';

class TeamMember {
  final String id;
  final String name;
  final String email;
  final String role;
  final Color avatarColor;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarColor,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return TeamMember(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'Member',
      // Backend stores no colour — derive one deterministically from the id.
      avatarColor: avatarColorFor(id),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  @override
  bool operator ==(Object other) => other is TeamMember && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
