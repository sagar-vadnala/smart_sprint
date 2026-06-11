import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/adaptive_sheet.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';
import 'package:smart_sprint/features/workspace/data/json_mappers.dart';
import 'package:smart_sprint/features/workspace/data/workspace_repository.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/space_template.dart';
import 'package:smart_sprint/features/workspace/view/widgets/workspace_badge.dart';

/// Opens the template gallery. Resolves to `true` once a space has been created
/// from a template (so the caller can dismiss its own create sheet), or `null`
/// if the user backed out.
Future<bool?> showTemplateGallery(BuildContext context) {
  final bloc = context.read<WorkspaceBloc>();
  return showAdaptiveSheet<bool>(
    context: context,
    builder: (_) => BlocProvider.value(value: bloc, child: const _TemplateFlow()),
  );
}

enum _Step { pick, configure, building }

class _TemplateFlow extends StatefulWidget {
  const _TemplateFlow();

  @override
  State<_TemplateFlow> createState() => _TemplateFlowState();
}

class _TemplateFlowState extends State<_TemplateFlow> {
  final _repo = WorkspaceRepository();
  final _nameController = TextEditingController();

  _Step _step = _Step.pick;
  SpaceTemplate? _selected;
  Color _color = const Color(0xFF6C47FF);
  String? _error;

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

  void _choose(SpaceTemplate t) {
    setState(() {
      _selected = t;
      _color = t.accent;
      _nameController.text = t.id == 'blank' ? '' : t.name;
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nameController.text.length,
      );
      _step = _Step.configure;
      _error = null;
    });
  }

  Future<void> _create() async {
    final template = _selected!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your space a name.');
      return;
    }

    setState(() {
      _step = _Step.building;
      _error = null;
    });

    final bloc = context.read<WorkspaceBloc>();
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);

    try {
      // Run the build alongside a short minimum so the animation never just
      // flashes (a blank space creates in a single call).
      final results = await Future.wait([
        _repo.buildTemplateSpace(
          organizationId: bloc.state.currentOrganizationId,
          name: name,
          color: colorToInt(_color),
          iconKey: workspaceIconKey(
            icon: template.spaceIcon,
            shape: IconShape.roundedSquare,
            useLetter: false,
          ),
          template: template,
        ),
        Future.delayed(const Duration(milliseconds: 900)),
      ]);
      final built = results.first as TemplateBuildResult;

      if (!mounted) return;
      bloc.add(
        SpaceImported(
          project: built.project,
          sprints: built.sprints,
          tasks: built.tasks,
        ),
      );
      // Close this dialog (true → the create sheet above closes itself too),
      // then open the new space once the whole modal stack has unwound. Doing
      // the push now would land it *under* the create sheet that's about to pop.
      final newId = built.project.id;
      navigator.pop(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push('/w/$newId');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = _Step.configure;
        _error = 'Something went wrong creating the space. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: sheetSurfaceDecoration(context),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          Flexible(child: switch (_step) {
            _Step.pick => _PickView(onChoose: _choose),
            _Step.configure => _ConfigureView(
              template: _selected!,
              nameController: _nameController,
              color: _color,
              palette: _palette,
              error: _error,
              onColor: (c) => setState(() => _color = c),
              onBack: () => setState(() => _step = _Step.pick),
              onCreate: _create,
            ),
            _Step.building => _BuildingView(template: _selected!, color: _color),
          }),
        ],
      ),
    );
  }
}

// ─── Step 1: pick a template ──────────────────────────────────────────────────

class _PickView extends StatelessWidget {
  final ValueChanged<SpaceTemplate> onChoose;

  const _PickView({required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.brand,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Template Center',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a starting point — we\'ll set up the space for you.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: muted),
          ),
          const SizedBox(height: 16),
          ...kSpaceTemplates.map(
            (t) => _TemplateCard(template: t, onTap: () => onChoose(t)),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final SpaceTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final meta = template.isBlank
        ? 'Empty space'
        : '${template.sprintCount} ${template.sprintCount == 1 ? 'sprint' : 'sprints'} · ${template.taskCount} tasks';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: template.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(template.icon, color: template.accent, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.tagline,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: muted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: template.accent,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: muted),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: configure (name + colour) ────────────────────────────────────────

class _ConfigureView extends StatelessWidget {
  final SpaceTemplate template;
  final TextEditingController nameController;
  final Color color;
  final List<Color> palette;
  final String? error;
  final ValueChanged<Color> onColor;
  final VoidCallback onBack;
  final VoidCallback onCreate;

  const _ConfigureView({
    required this.template,
    required this.nameController,
    required this.color,
    required this.palette,
    required this.error,
    required this.onColor,
    required this.onBack,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 20, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkFill : AppColors.lightFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: textColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  template.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    WorkspaceBadge.preview(
                      name: nameController.text,
                      color: color,
                      icon: template.spaceIcon,
                      shape: IconShape.roundedSquare,
                      useLetter: false,
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => onCreate(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Space name',
                          errorText: error,
                        ),
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
                  runSpacing: 12,
                  children: palette.map((c) {
                    final sel = c == color;
                    return GestureDetector(
                      onTap: () => onColor(c),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                        child: sel
                            ? const Icon(
                                Icons.check_rounded,
                                size: 17,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                if (!template.isBlank) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkFill
                          : AppColors.lightFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            "We'll create ${template.sprintCount > 0 ? '${template.sprintCount} sprint(s) and ' : ''}${template.taskCount} sample tasks for you.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCreate,
              child: Text(template.isBlank ? 'Create Space' : 'Use Template'),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Step 3: building animation ───────────────────────────────────────────────

class _BuildingView extends StatefulWidget {
  final SpaceTemplate template;
  final Color color;

  const _BuildingView({required this.template, required this.color});

  @override
  State<_BuildingView> createState() => _BuildingViewState();
}

class _BuildingViewState extends State<_BuildingView> {
  static const _messages = [
    'Creating your space…',
    'Setting up sprints…',
    'Adding tasks…',
    'Applying statuses & priorities…',
    'Almost there…',
  ];

  int _msg = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (!mounted) return;
      setState(() => _msg = (_msg + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(widget.color),
                    backgroundColor: widget.color.withValues(alpha: 0.12),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    widget.template.icon,
                    color: widget.color,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Building “${widget.template.name}”',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _messages[_msg],
              key: ValueKey(_msg),
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
