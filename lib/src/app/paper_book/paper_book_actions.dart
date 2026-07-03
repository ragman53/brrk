import 'package:brrk/src/rust/api/models.dart';
import 'package:flutter/material.dart';

void showPaperPageActions(
  BuildContext context, {
  required PaperPage page,
  required int index,
  required Future<void> Function(PaperPage page, int index) onEditPageLabel,
  required Future<void> Function(PaperPage page, int index) onDeletePage,
}) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('Edit Page Label'),
            onTap: () {
              Navigator.pop(context);
              onEditPageLabel(page, index);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete Page',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              onDeletePage(page, index);
            },
          ),
        ],
      ),
    ),
  );
}
