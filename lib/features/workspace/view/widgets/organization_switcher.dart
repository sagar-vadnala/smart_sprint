import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';
import 'package:smart_sprint/features/workspace/model/organization.dart';

/// Compact pill shown in the Home header. Tapping opens the switcher.
class OrganizationPill extends StatelessWidget {
  const OrganizationPill({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final org = context.watch<WorkspaceBloc>().state.currentOrganization;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return GestureDetector(
      onTap: () => showOrganizationSwitcher(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OrgBadge(org: org, size: 24),
            const SizedBox(width: 7),
            Text(
              org.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(width: 1),
            Icon(Icons.unfold_more_rounded, size: 15, color: muted),
          ],
        ),
      ),
    );
  }
}

class _OrgBadge extends StatelessWidget {
  final Organization org;
  final double size;

  const _OrgBadge({required this.org, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: org.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(org.icon, size: size * 0.58, color: org.color),
    );
  }
}

Future<void> showOrganizationSwitcher(BuildContext context) {
  final bloc = context.read<WorkspaceBloc>();
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: const _SwitcherSheet(),
    ),
  );
}

class _SwitcherSheet extends StatelessWidget {
  const _SwitcherSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
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
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
            child: Row(
              children: [
                Text(
                  'Switch organization',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Row(
              children: [
                Text(
                  'You belong to ${state.organizations.length} ${state.organizations.length == 1 ? 'org' : 'orgs'}',
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              children: [
                ...state.organizations.map((o) {
                  final selected = o.id == state.currentOrganizationId;
                  final workspaceCount = state.allProjects
                      .where((p) => p.organizationId == o.id)
                      .length;
                  return _OrgRow(
                    org: o,
                    selected: selected,
                    subtitle:
                        '${o.type.label} · $workspaceCount workspaces · ${o.memberIds.length} ${o.memberIds.length == 1 ? 'member' : 'members'}',
                    onTap: () {
                      context
                          .read<WorkspaceBloc>()
                          .add(OrganizationSwitched(o.id));
                      Navigator.of(context).pop();
                    },
                  );
                }),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showCreateOrganization(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: AppColors.brand, size: 22),
                        ),
                        const SizedBox(width: 13),
                        Text(
                          'Create organization',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8 + MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgRow extends StatelessWidget {
  final Organization org;
  final bool selected;
  final String subtitle;
  final VoidCallback onTap;

  const _OrgRow({
    required this.org,
    required this.selected,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? org.color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? org.color : border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: org.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(org.icon, color: org.color, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        org.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      if (org.isPersonal) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: org.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'YOU',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: org.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: org.color, size: 22)
            else
              Icon(Icons.circle_outlined, color: border, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Create organization ──────────────────────────────────────────────────────

void _showCreateOrganization(BuildContext context) {
  final bloc = context.read<WorkspaceBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _CreateOrgSheet(),
      ),
    ),
  );
}

class _CreateOrgSheet extends StatefulWidget {
  const _CreateOrgSheet();

  @override
  State<_CreateOrgSheet> createState() => _CreateOrgSheetState();
}

class _CreateOrgSheetState extends State<_CreateOrgSheet> {
  final _nameController = TextEditingController();
  OrgType _type = OrgType.team;
  Color _color = const Color(0xFF14B8A6);

  static const _palette = [
    Color(0xFF6C47FF),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<WorkspaceBloc>().add(OrganizationCreated(
          name: name,
          type: _type,
          color: _color,
          icon: _type.isPersonal
              ? Icons.person_rounded
              : Icons.hexagon_rounded,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                22, 0, 22, 16 + MediaQuery.paddingOf(context).bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New organization',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A space for a company or team you run',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Organization name',
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'TYPE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TypeCard(
                        title: 'Personal',
                        subtitle: 'Just you',
                        icon: Icons.person_rounded,
                        selected: _type == OrgType.personal,
                        onTap: () =>
                            setState(() => _type = OrgType.personal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeCard(
                        title: 'Team',
                        subtitle: 'Invite people',
                        icon: Icons.groups_rounded,
                        selected: _type == OrgType.team,
                        onTap: () => setState(() => _type = OrgType.team),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'COLOR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  children: _palette.map((c) {
                    final sel = c == _color;
                    return GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                        child: sel
                            ? const Icon(Icons.check_rounded,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Create organization'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brand : border,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.brand : muted),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
