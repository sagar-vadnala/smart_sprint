import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import '../cubit/onboarding_cubit.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _PageData {
  final Color bgColor;
  final String tag;
  final String title;
  final String subtitle;
  final Widget illustration;

  const _PageData({
    required this.bgColor,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  static const _pages = [
    _PageData(
      bgColor: AppColors.ob1,
      tag: 'ORGANISE',
      title: 'Plan with\nclarity.',
      subtitle:
          'Break work into projects, sprints, and tasks. Keep every deadline visible and every blocker surfaced early.',
      illustration: _BoardIllustration(),
    ),
    _PageData(
      bgColor: AppColors.ob2,
      tag: 'MEASURE',
      title: 'Track what\nactually matters.',
      subtitle:
          'Real-time progress across every initiative. Spot risks before they become delays.',
      illustration: _ProgressIllustration(),
    ),
    _PageData(
      bgColor: AppColors.ob3,
      tag: 'COLLABORATE',
      title: 'Ship fast,\ntogether.',
      subtitle:
          'Assign work, leave comments, and close tasks — all without switching apps.',
      illustration: _TeamIllustration(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: BlocConsumer<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              state.currentPage,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeInOutCubic,
            );
          }
          if (state.isComplete) context.go('/login');
        },
        builder: (context, state) {
          final cubit = context.read<OnboardingCubit>();
          return Scaffold(
            backgroundColor: Colors.black,
            body: PageView.builder(
              controller: _pageController,
              onPageChanged: cubit.goToPage,
              itemCount: _pages.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (_, i) => _OnboardingPage(
                data: _pages[i],
                index: i,
                onNext: i < 2 ? cubit.nextPage : cubit.finish,
                onBack: cubit.previousPage,
                onSkip: cubit.skip,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Single page ──────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  final int index;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const _OnboardingPage({
    required this.data,
    required this.index,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final contentBg = isDark ? AppColors.darkSurface : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Illustration area (no rounded bottom, full bleed) ──────────────
        SizedBox(
          height: size.height * 0.56,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: data.bgColor,
                  child: data.illustration,
                ),
              ),
              // Skip
              if (index < 2)
                Positioned(
                  top: insets.top + 14,
                  right: 20,
                  child: GestureDetector(
                    onTap: onSkip,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Content area (flat top edge — intentional, not rounded) ────────
        Expanded(
          child: Container(
            color: contentBg,
            padding: EdgeInsets.fromLTRB(28, 26, 28, insets.bottom + 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line indicators + tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 3 thin bars
                    ...List.generate(3, (i) {
                      final active = i == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 5),
                        width: active ? 24 : 10,
                        height: 3,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.brand
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                    const SizedBox(width: 10),
                    Text(
                      data.tag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  data.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    letterSpacing: -0.8,
                    color:
                        isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),

                const SizedBox(height: 11),

                // Subtitle
                Text(
                  data.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),

                const Spacer(),

                // Navigation
                Row(
                  children: [
                    // Back (circle, hidden on first page)
                    AnimatedOpacity(
                      opacity: index > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: GestureDetector(
                        onTap: index > 0 ? onBack : null,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Next / Get Started
                    GestureDetector(
                      onTap: onNext,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              index < 2 ? 'Next' : 'Get Started',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Illustration 1 — Kanban board ────────────────────────────────────────────

class _BoardIllustration extends StatelessWidget {
  const _BoardIllustration();

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(18, insets.top + 60, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.taskAmber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Sprint 23  ·  Apr 15 – Apr 30',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '12 tasks',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: _KanbanCol(
                    label: 'TO DO',
                    count: '4',
                    cards: [
                      _TaskCard(accent: AppColors.taskAmber, lines: 2),
                      _TaskCard(accent: AppColors.taskBlue, lines: 1),
                      _TaskCard(accent: Color(0xFFFCA5A5), lines: 2),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _KanbanCol(
                    label: 'IN PROGRESS',
                    count: '2',
                    cards: [
                      _TaskCard(
                        accent: Color(0xFFA5F3FC),
                        lines: 2,
                        progress: 0.6,
                        hasAvatar: true,
                      ),
                      _TaskCard(
                        accent: AppColors.taskAmber,
                        lines: 1,
                        progress: 0.25,
                        hasAvatar: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _KanbanCol(
                    label: 'DONE',
                    count: '6',
                    cards: [
                      _TaskCard(
                          accent: AppColors.taskGreen,
                          lines: 2,
                          isDone: true),
                      _TaskCard(
                          accent: AppColors.taskGreen,
                          lines: 1,
                          isDone: true),
                      _TaskCard(
                          accent: AppColors.taskGreen,
                          lines: 1,
                          isDone: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCol extends StatelessWidget {
  final String label;
  final String count;
  final List<Widget> cards;

  const _KanbanCol({
    required this.label,
    required this.count,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    count,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...cards.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Color accent;
  final int lines;
  final double? progress;
  final bool hasAvatar;
  final bool isDone;

  const _TaskCard({
    required this.accent,
    required this.lines,
    this.progress,
    this.hasAvatar = false,
    this.isDone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDone ? 0.07 : 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: isDone ? accent.withValues(alpha: 0.35) : accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Bar(double.infinity, isDone ? 0.22 : 0.6),
                  if (lines > 1) ...[
                    const SizedBox(height: 4),
                    _Bar(38, isDone ? 0.13 : 0.32),
                  ],
                  if (progress != null) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation(accent),
                        minHeight: 2.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasAvatar) ...[
              const SizedBox(width: 5),
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
              ),
            ],
            if (isDone) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.taskGreen, size: 11),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double opacity;

  const _Bar(this.width, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ─── Illustration 2 — Progress dashboard ──────────────────────────────────────

class _ProgressIllustration extends StatelessWidget {
  const _ProgressIllustration();

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(18, insets.top + 52, 18, 20),
      child: Column(
        children: [
          // Stat row
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'DONE',
                  value: '47',
                  sub: '+12 this week',
                  dot: AppColors.taskGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'IN REVIEW',
                  value: '8',
                  sub: '3 overdue',
                  dot: AppColors.taskAmber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'BLOCKED',
                  value: '2',
                  sub: 'needs action',
                  dot: const Color(0xFFFCA5A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main card
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q2 SPRINT',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '73%',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'completion',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 68,
                        height: 68,
                        child: CustomPaint(
                          painter: _DonutPainter(
                            progress: 0.73,
                            fg: Colors.white,
                            bg: Colors.white24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...[
                    ('Design', 0.88, AppColors.taskGreen),
                    ('Development', 0.67, AppColors.taskAmber),
                    ('QA', 0.44, const Color(0xFFFCA5A5)),
                  ].map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                row.$1,
                                style: GoogleFonts.plusJakartaSans(
                                  color:
                                      Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(row.$2 * 100).round()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  color:
                                      Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: row.$2,
                              backgroundColor: Colors.white12,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(row.$3),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color dot;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.sub,
    required this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                    color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  sub,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color fg;
  final Color bg;

  const _DonutPainter({
    required this.progress,
    required this.fg,
    required this.bg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width / 2) - stroke / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = bg
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = fg
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.fg != fg;
}

// ─── Illustration 3 — Team activity ───────────────────────────────────────────

class _TeamIllustration extends StatelessWidget {
  const _TeamIllustration();

  static const _avatarData = [
    ('S', Color(0xFF7C6AF7)),
    ('A', Color(0xFF34D399)),
    ('J', Color(0xFFFBBF24)),
    ('R', Color(0xFFF472B6)),
    ('M', Color(0xFF60A5FA)),
  ];

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(18, insets.top + 52, 18, 20),
      child: Column(
        children: [
          // Active members bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Stacked avatars
                SizedBox(
                  width: 5 * 18.0 + 10,
                  height: 24,
                  child: Stack(
                    children: List.generate(
                      _avatarData.length,
                      (i) => Positioned(
                        left: i * 18.0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _avatarData[i].$2,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.ob3,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _avatarData[i].$1,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '5 members online',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Activity feed
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECENT ACTIVITY',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _ActivityRow(
                    avatarIndex: 0,
                    action: 'completed',
                    task: 'Design System v2',
                    time: '2m',
                    done: true,
                  ),
                  _HRule(),
                  const _ActivityRow(
                    avatarIndex: 1,
                    action: 'commented on',
                    task: 'API Integration',
                    time: '9m',
                    done: false,
                  ),
                  _HRule(),
                  const _ActivityRow(
                    avatarIndex: 2,
                    action: 'moved to review',
                    task: 'Auth flow',
                    time: '23m',
                    done: false,
                  ),
                  _HRule(),
                  const _ActivityRow(
                    avatarIndex: 3,
                    action: 'created',
                    task: 'Fix payment bug',
                    time: '1h',
                    done: false,
                  ),
                  const Spacer(),

                  // Bottom stat row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.taskGreen,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '14 tasks closed today',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '↑ 23%',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.taskGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final int avatarIndex;
  final String action;
  final String task;
  final String time;
  final bool done;

  const _ActivityRow({
    required this.avatarIndex,
    required this.action,
    required this.task,
    required this.time,
    required this.done,
  });

  static const _avatars = [
    ('S', Color(0xFF7C6AF7)),
    ('A', Color(0xFF34D399)),
    ('J', Color(0xFFFBBF24)),
    ('R', Color(0xFFF472B6)),
  ];

  @override
  Widget build(BuildContext context) {
    final av = _avatars[avatarIndex.clamp(0, _avatars.length - 1)];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: av.$2,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                av.$1,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                children: [
                  TextSpan(text: '$action '),
                  TextSpan(
                    text: task,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          done
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.taskGreen,
                  size: 13,
                )
              : Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.28),
                    fontSize: 10,
                  ),
                ),
        ],
      ),
    );
  }
}

class _HRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}
