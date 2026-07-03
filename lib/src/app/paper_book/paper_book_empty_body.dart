import 'package:flutter/material.dart';

class EmptyBookBody extends StatelessWidget {
  final VoidCallback onAddPage;
  const EmptyBookBody({super.key, required this.onAddPage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No pages yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Capture pages to add them to this book.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddPage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Page'),
            ),
          ],
        ),
      ),
    );
  }
}
