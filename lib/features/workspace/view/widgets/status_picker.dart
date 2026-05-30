import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';

/// Captures the tap position and hands it to [onTap] so callers can open an
/// anchored dropdown right where the user tapped.
class AnchoredTap extends StatefulWidget {
  final Widget child;
  final Future<void> Function(Offset globalPosition) onTap;

  const AnchoredTap({super.key, required this.child, required this.onTap});

  @override
  State<AnchoredTap> createState() => _AnchoredTapState();
}

class _AnchoredTapState extends State<AnchoredTap> {
  Offset _pos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _pos = d.globalPosition,
      onTap: () => widget.onTap(_pos),
      child: widget.child,
    );
  }
}

/// A tappable status indicator for task tiles. Opens the status dropdown.
class StatusPickerButton extends StatelessWidget {
  final Task task;
  final double size;

  const StatusPickerButton({super.key, required this.task, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    return AnchoredTap(
      onTap: (pos) async {
        final s = await pickStatus(context, pos, task.status);
        if (s != null && s != task.status && context.mounted) {
          context.read<WorkspaceBloc>().add(TaskStatusChanged(task.id, s));
        }
      },
      child: StatusDot(status: task.status, size: size, done: done),
    );
  }
}

/// The circular status indicator (filled check for done, dot for in-progress).
class StatusDot extends StatelessWidget {
  final TaskStatus status;
  final double size;
  final bool done;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 20,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = done || status == TaskStatus.done;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? AppColors.success : Colors.transparent,
        border: Border.all(
          color: isDone ? AppColors.success : status.color,
          width: 1.8,
        ),
      ),
      child: isDone
          ? Icon(Icons.check_rounded, size: size * 0.62, color: Colors.white)
          : (status == TaskStatus.inProgress
                ? Center(
                    child: Container(
                      width: size * 0.34,
                      height: size * 0.34,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null),
    );
  }
}

/// Shows an anchored dropdown of statuses; returns the chosen one (or null).
Future<TaskStatus?> pickStatus(
  BuildContext context,
  Offset globalPosition,
  TaskStatus current,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  return showMenu<TaskStatus>(
    context: context,
    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    ),
    position: RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    ),
    items: [
      _menuHeader('MOVE TO', isDark),
      ...TaskStatus.values.map((s) {
        final isCurrent = s == current;
        return PopupMenuItem<TaskStatus>(
          value: s,
          height: 44,
          child: _menuRow(
            dotColor: s.color,
            label: s.label,
            isCurrent: isCurrent,
            isDark: isDark,
          ),
        );
      }),
    ],
  );
}

/// Shows an anchored dropdown of priorities; returns the chosen one (or null).
Future<TaskPriority?> pickPriority(
  BuildContext context,
  Offset globalPosition,
  TaskPriority current,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  return showMenu<TaskPriority>(
    context: context,
    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    ),
    position: RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    ),
    items: [
      _menuHeader('PRIORITY', isDark),
      ...TaskPriority.values.map((p) {
        final isCurrent = p == current;
        return PopupMenuItem<TaskPriority>(
          value: p,
          height: 44,
          child: Row(
            children: [
              Icon(Icons.flag_rounded, size: 15, color: p.color),
              const SizedBox(width: 10),
              Text(
                p.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const Spacer(),
              if (isCurrent)
                Icon(Icons.check_rounded, size: 16, color: p.color),
            ],
          ),
        );
      }),
    ],
  );
}

/// Bottom-sheet priority picker (for menu-triggered selection where there is no
/// tap anchor). [onPick] receives null when the user chooses "No priority".
Future<void> showPriorityPicker(
  BuildContext context, {
  required TaskPriority? current,
  required ValueChanged<TaskPriority?> onPick,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  Widget row({
    required Widget leading,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_rounded, size: 18, color: AppColors.brand),
          ],
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          for (final p in TaskPriority.values)
            row(
              leading: Icon(Icons.flag_rounded, size: 18, color: p.color),
              label: p.label,
              selected: p == current,
              onTap: () {
                onPick(p);
                Navigator.of(context).pop();
              },
            ),
          row(
            leading: Icon(Icons.flag_outlined, size: 18, color: muted),
            label: 'No priority',
            selected: current == null,
            onTap: () {
              onPick(null);
              Navigator.of(context).pop();
            },
          ),
          SizedBox(height: 8 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    ),
  );
}

PopupMenuItem<T> _menuHeader<T>(String label, bool isDark) {
  return PopupMenuItem<T>(
    enabled: false,
    height: 30,
    child: Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
    ),
  );
}

Widget _menuRow({
  required Color dotColor,
  required String label,
  required bool isCurrent,
  required bool isDark,
}) {
  return Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      const SizedBox(width: 11),
      Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
      const Spacer(),
      if (isCurrent) Icon(Icons.check_rounded, size: 16, color: dotColor),
    ],
  );
}
