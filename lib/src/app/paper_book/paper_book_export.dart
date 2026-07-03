import 'dart:convert';

import 'package:brrk/src/rust/api/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExportJsonSheet extends StatefulWidget {
  final PaperBook book;
  const ExportJsonSheet({super.key, required this.book});

  @override
  State<ExportJsonSheet> createState() => _ExportJsonSheetState();
}

class _ExportJsonSheetState extends State<ExportJsonSheet> {
  late final List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.book.pages.length, true);
  }

  Future<void> _copyToClipboard() async {
    final pages = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.book.pages.length; i++) {
      if (!_selected[i]) continue;
      final page = widget.book.pages[i];
      pages.add({
        'capture_index': i + 1,
        'page_label': page.pageLabel,
        // Export the displayed reader text: manual edit takes precedence
        // over the original OCR. Original OCR is preserved on disk in
        // PaperPage.markdown and remains available via "Reset to OCR".
        'markdown': page.manualMarkdown ?? page.markdown,
        'notes': page.notes
            .map(
              (n) => {
                'selected_text': n.selectedText,
                'start_offset': n.startOffset,
                'end_offset': n.endOffset,
                'content': n.content,
                'tags': n.tags,
                'created_at': n.createdAt,
                'updated_at': n.updatedAt,
              },
            )
            .toList(),
      });
    }
    final json = const JsonEncoder.withIndent('  ').convert({
      'type': 'brrk.paper_pages_export',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'book': {'title': widget.book.title},
      'pages': pages,
    });
    final bytes = utf8.encode(json);
    if (bytes.length > 500 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export is large (>500KB). Copying anyway.'),
        ),
      );
    }
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('JSON copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Export Pages', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Select pages to export as JSON.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.book.pages.length; i++)
                    CheckboxListTile(
                      value: _selected[i],
                      onChanged: (v) =>
                          setState(() => _selected[i] = v ?? true),
                      title: Text(
                        widget.book.pages[i].pageLabel != null
                            ? 'p. ${widget.book.pages[i].pageLabel}'
                            : 'Capture ${i + 1}',
                      ),
                      subtitle: Text(
                        widget.book.pages[i].markdown.substring(
                          0,
                          widget.book.pages[i].markdown.length.clamp(0, 60),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _selected.contains(true) ? _copyToClipboard : null,
                child: const Text('Copy JSON'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
