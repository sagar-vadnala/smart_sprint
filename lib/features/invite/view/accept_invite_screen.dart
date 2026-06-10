import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/api/api_client.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/auth/data/auth_repository.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';
import 'package:smart_sprint/features/workspace/data/workspace_repository.dart';

/// Landing screen for an invitation link (`/invite/:token`).
///
/// Shows who invited you and to which org, then lets you accept. If you're not
/// signed in, it routes you to login/signup and brings you back here afterward.
class AcceptInviteScreen extends StatefulWidget {
  final String token;

  const AcceptInviteScreen({super.key, required this.token});

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  final _repo = WorkspaceRepository();
  final _auth = AuthRepository();

  bool _loading = true;
  bool _loggedIn = false;
  InvitePreview? _preview;
  String? _loadError;

  bool _accepting = false;
  String? _acceptError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loggedIn = await _auth.hasToken();
      final preview = await _repo.getInvite(widget.token);
      if (!mounted) return;
      setState(() {
        _loggedIn = loggedIn;
        _preview = preview;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  String get _next => Uri.encodeComponent('/invite/${widget.token}');

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _acceptError = null;
    });
    try {
      final org = await _repo.acceptInvite(widget.token);
      if (!mounted) return;
      context.read<WorkspaceBloc>().add(OrganizationJoined(org.id));
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _accepting = false;
        _acceptError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _body(),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _Message(
        icon: Icons.link_off_rounded,
        iconColor: AppColors.error,
        title: 'Invitation unavailable',
        body: _loadError!,
        primaryLabel: 'Go to SmartSprint',
        onPrimary: () => context.go('/'),
      );
    }

    final p = _preview!;
    if (p.status != 'pending') {
      final msg = switch (p.status) {
        'accepted' => 'This invitation has already been used.',
        'revoked' => 'This invitation was revoked by the organization.',
        'expired' => 'This invitation has expired. Ask for a new one.',
        _ => 'This invitation is no longer valid.',
      };
      return _Message(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.warning,
        title: 'Invitation ${p.status}',
        body: msg,
        primaryLabel: 'Go to SmartSprint',
        onPrimary: () => context.go('/'),
      );
    }

    return _invitationCard(p);
  }

  Widget _invitationCard(InvitePreview p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.brandGradient),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.groups_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 20),
        Text(
          "You're invited",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          p.organizationName,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${p.inviterName} invited you to collaborate.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: muted),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email_outlined, size: 15, color: muted),
              const SizedBox(width: 7),
              Text(
                p.email,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (_acceptError != null) ...[
          Text(
            _acceptError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (_loggedIn)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _accepting ? null : _accept,
              child: _accepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Accept invitation'),
            ),
          )
        else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/signup?next=$_next'),
              child: const Text('Create account to join'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/login?next=$_next'),
              child: const Text('I already have an account'),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sign in with ${p.email} to accept this invite.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: muted),
          ),
        ],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;

  const _Message({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 44),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: muted),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: onPrimary, child: Text(primaryLabel)),
        ),
      ],
    );
  }
}
