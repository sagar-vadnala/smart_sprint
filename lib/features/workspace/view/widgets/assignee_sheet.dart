import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/model/team_member.dart';
import 'member_avatar.dart';

/// Bottom sheet to pick assignees. Calls [onChanged] live on every toggle so
/// the underlying screen updates in real time.
Future<void> showAssigneeSheet(
  BuildContext context, {
  required List<TeamMember> members,
  required List<String> selected,
  required ValueChanged<List<String>> onChanged,
  String title = 'Assignees',
}) {
  final bloc = context.read<WorkspaceBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _AssigneeSheet(
        members: members,
        initial: selected,
        onChanged: onChanged,
        title: title,
      ),
    ),
  );
}

class _AssigneeSheet extends StatefulWidget {
  final List<TeamMember> members;
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;
  final String title;

  const _AssigneeSheet({
    required this.members,
    required this.initial,
    required this.onChanged,
    required this.title,
  });

  @override
  State<_AssigneeSheet> createState() => _AssigneeSheetState();
}

class _AssigneeSheetState extends State<_AssigneeSheet> {
  late final Set<String> _selected = {...widget.initial};

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    widget.onChanged(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selected.length} selected',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              children: [
                ...widget.members.map((m) {
                  final sel = _selected.contains(m.id);
                  return GestureDetector(
                    onTap: () => _toggle(m.id),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.brand.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          MemberAvatar(member: m, size: 38),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.id == 'me' ? 'You' : m.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  m.role,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sel ? AppColors.brand : Colors.transparent,
                              border: Border.all(
                                color: sel ? AppColors.brand : border,
                                width: 1.6,
                              ),
                            ),
                            child: sel
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 8 + MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
