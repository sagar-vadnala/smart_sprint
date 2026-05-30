import 'package:flutter/material.dart';

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
