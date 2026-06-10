import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/api/api_client.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/adaptive_sheet.dart';
import 'package:smart_sprint/features/workspace/data/workspace_repository.dart';

/// Opens the "invite a teammate" bottom sheet for [organizationId].
///
/// Sends a real email invitation: the invitee receives a link to accept and
/// join the org (they don't need an account yet). If the server has no email
/// provider configured, we show the accept link so the admin can share it.
Future<void> showInviteMemberSheet(
  BuildContext context,
  String organizationId,
) {
  return showAdaptiveSheet(
    context: context,
    builder: (sheetContext) => useGlassDialog(sheetContext)
        ? _InviteSheet(organizationId: organizationId)
        : Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: _InviteSheet(organizationId: organizationId),
          ),
  );
}

class _InviteSheet extends StatefulWidget {
  final String organizationId;

  const _InviteSheet({required this.organizationId});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _controller = TextEditingController();
  final _repo = WorkspaceRepository();
  bool _loading = false;
  String? _error;

  // Set once an invite is created but email couldn't be sent — we surface the
  // link for the admin to share manually.
  InviteResult? _shareLink;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _validEmail(String v) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim());

  Future<void> _invite() async {
    final email = _controller.text.trim();
    if (!_validEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.createInvite(widget.organizationId, email);
      if (!mounted) return;
      if (result.emailSent) {
        Navigator.of(context).pop();
        _toast(context, 'Invitation sent to ${result.email}');
      } else {
        // No email provider — show the link to copy/share instead.
        setState(() {
          _loading = false;
          _shareLink = result;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      decoration: sheetSurfaceDecoration(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetGrabber()),
            const SizedBox(height: 8),
            if (_shareLink != null)
              _shareLinkView(textColor, muted, border)
            else
              _formView(textColor, muted),
          ],
        ),
      ),
    );
  }

  Widget _formView(Color textColor, Color muted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invite a teammate',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "We'll email them a link to join. They can create a SmartSprint "
          "account from there if they don't have one yet.",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: muted),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _invite(),
          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textColor),
          decoration: InputDecoration(
            hintText: 'teammate@company.com',
            prefixIcon: const Icon(
              Icons.email_outlined,
              size: 18,
              color: AppColors.lightTextMuted,
            ),
            errorText: _error,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _invite,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Send invite'),
        ),
      ],
    );
  }

  Widget _shareLinkView(Color textColor, Color muted, Color border) {
    final link = _shareLink!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Invitation created',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Email isn't set up on the server yet, so copy this link and send it "
          "to ${link.email} so they can join:",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: muted),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            link.acceptUrl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.robotoMono(fontSize: 12.5, color: textColor),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link.acceptUrl));
                  if (mounted) _toast(context, 'Invite link copied');
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy link'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
