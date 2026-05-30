import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';

/// Tap-to-edit text. Shows [value] as text; on tap it becomes a focused
/// TextField. Commits via [onCommit] when focus is lost, on submit, or when the
/// widget is disposed (e.g. navigating away) — but only if the value changed.
///
/// IMPORTANT: [onCommit] must NOT use the calling `context` (it can fire during
/// dispose). Capture the bloc once in the parent's build and call it directly.
class InlineEditableText extends StatefulWidget {
  final String value;
  final ValueChanged<String> onCommit;
  final TextStyle style;
  final String hintText;
  final int? maxLines;

  /// When true, an empty submission is ignored and reverts to [value]
  /// (use for titles). When false, empty is allowed (use for descriptions).
  final bool required;

  const InlineEditableText({
    super.key,
    required this.value,
    required this.onCommit,
    required this.style,
    this.hintText = '',
    this.maxLines = 1,
    this.required = true,
  });

  @override
  State<InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<InlineEditableText> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(InlineEditableText old) {
    super.didUpdateWidget(old);
    // Keep in sync with external updates when not actively editing.
    if (!_editing && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _commit();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _commit();
      if (mounted) setState(() => _editing = false);
    }
  }

  void _commit() {
    final text = _controller.text.trim();
    if (widget.required && text.isEmpty) {
      _controller.text = widget.value; // revert
      return;
    }
    if (text != widget.value) {
      widget.onCommit(text);
    }
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final fill = isDark ? AppColors.darkFill : AppColors.lightFill;

    if (_editing) {
      return TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: widget.style,
        maxLines: widget.maxLines,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: AppColors.brand,
        onSubmitted: widget.maxLines == 1 ? (_) => _focusNode.unfocus() : null,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
        ),
      );
    }

    final isEmpty = widget.value.trim().isEmpty;
    return InkWell(
      onTap: _startEditing,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          isEmpty ? widget.hintText : widget.value,
          maxLines: widget.maxLines,
          overflow: TextOverflow.ellipsis,
          style: isEmpty ? widget.style.copyWith(color: muted) : widget.style,
        ),
      ),
    );
  }
}

TextStyle inlineTitleStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: isDark ? AppColors.darkText : AppColors.lightText,
  );
}
