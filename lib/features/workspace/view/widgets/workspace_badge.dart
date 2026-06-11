import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/project.dart';

/// The icon badge for a workspace/space. Renders either a ClickUp-style letter
/// avatar (solid colour + white initial) or a glyph on a tinted surface,
/// clipped to the workspace's chosen [IconShape].
///
/// Centralising this keeps every place that shows a space — sidebar, spaces
/// list, breadcrumbs, search, move-to picker — visually consistent.
class WorkspaceBadge extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final IconShape shape;
  final bool useLetter;
  final double size;

  const WorkspaceBadge({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    required this.shape,
    required this.useLetter,
    this.size = 28,
  });

  /// Convenience: build straight from a [Project].
  WorkspaceBadge.project(Project project, {super.key, this.size = 28})
    : name = project.name,
      color = project.color,
      icon = project.icon,
      shape = project.shape,
      useLetter = project.useLetter;

  /// Build from in-progress create-sheet values (no Project yet).
  const WorkspaceBadge.preview({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    required this.shape,
    required this.useLetter,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final radius = shape.radius(size);

    if (useLetter) {
      final trimmed = name.trim();
      final letter = trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: radius),
        child: Text(
          letter,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: radius,
      ),
      child: Icon(icon, color: color, size: size * 0.56),
    );
  }
}
