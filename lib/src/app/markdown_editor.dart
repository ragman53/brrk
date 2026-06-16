import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'reading_appearance.dart';

/// Result of [MarkdownEditorScreen] pop.
///
/// - [saved] = `true` and [text] non-null: user saved the edit.
/// - [saved] = `true` and [text] == initialText: no-op save; no Rust call.
/// - [reset] = `true`: user reset to OCR; caller should call save with `null`.
/// - [saved] = `false`, [reset] = `false`: user cancelled.
class MarkdownEditorResult {
  final bool saved;
  final bool reset;
  final String? text;

  const MarkdownEditorResult({
    required this.saved,
    required this.reset,
    this.text,
  });

  const MarkdownEditorResult.cancelled()
    : saved = false,
      reset = false,
      text = null;
}

/// Plain-Markdown source editor for paper pages and PDF pages.
///
/// Pops a [MarkdownEditorResult] on close. See class docs.
class MarkdownEditorScreen extends StatefulWidget {
  static const int maxLength = 10_000;

  final String title;
  final String? subtitle;
  final String initialText;
  final bool hasManualEdit;

  /// Async save callback. Receives the new text. Returns `true` on success.
  final Future<bool> Function(String newText) onSave;

  /// Async reset-to-OCR callback. Returns `true` on success.
  final Future<bool> Function() onReset;

  const MarkdownEditorScreen({
    super.key,
    required this.title,
    required this.initialText,
    required this.hasManualEdit,
    required this.onSave,
    required this.onReset,
    this.subtitle,
  });

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  late final TextEditingController _controller;
  bool _dirty = false;
  bool _saving = false;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isDirty = _controller.text != widget.initialText;
    if (isDirty != _dirty) {
      setState(() {
        _dirty = isDirty;
      });
    }
  }

  bool get _busy => _saving || _resetting;

  Future<void> _onCancelTap() async {
    if (_busy) return;
    if (!_dirty) {
      Navigator.of(context).pop(const MarkdownEditorResult.cancelled());
      return;
    }
    final discard = await _confirm(
      title: 'Discard changes?',
      message: 'Your edits to this page will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!discard || !mounted) return;
    Navigator.of(context).pop(const MarkdownEditorResult.cancelled());
  }

  Future<void> _onSaveTap() async {
    if (_busy) return;
    // No-op if text hasn't changed.
    if (!_dirty) {
      Navigator.of(context).pop(const MarkdownEditorResult.cancelled());
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSave(_controller.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save edit.')));
      return;
    }
    Navigator.of(context).pop(
      MarkdownEditorResult(saved: true, reset: false, text: _controller.text),
    );
  }

  Future<void> _onResetTap() async {
    if (_busy) return;
    final confirm = await _confirm(
      title: 'Reset to OCR?',
      message: 'Your edits to this page will be discarded.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (!confirm || !mounted) return;
    setState(() => _resetting = true);
    final ok = await widget.onReset();
    if (!mounted) return;
    setState(() => _resetting = false);
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to reset.')));
      return;
    }
    Navigator.of(
      context,
    ).pop(const MarkdownEditorResult(saved: false, reset: true));
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required bool destructive,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty && !_busy,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // User is trying to leave. Treat as cancel.
        await _onCancelTap();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: TextButton(
            onPressed: _busy ? null : _onCancelTap,
            child: const Text('Cancel'),
          ),
          leadingWidth: 72,
          actions: [
            TextButton(
              onPressed: _busy ? null : _onSaveTap,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  widget.subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (widget.hasManualEdit)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This page has a manual edit.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _onResetTap,
                      child: _resetting
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reset to OCR'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  maxLength: MarkdownEditorScreen.maxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontFamily: brrkSerifFontFamily,
                    fontFamilyFallback: brrkSerifFontFallback,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Markdown...',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Manual edits are saved locally.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
