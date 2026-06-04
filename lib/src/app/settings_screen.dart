import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brrk/src/app/api_key.dart';
import 'package:brrk/src/app/reading_appearance.dart';
import 'package:brrk/src/rust/api/storage.dart' as storage;
import 'package:url_launcher/url_launcher.dart';

const _privacyPolicyUrl = 'https://ragman53.github.io/brrk/privacy.html';
const _termsOfUseUrl = 'https://ragman53.github.io/brrk/terms.html';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;
  String? _errorText;
  bool _saving = false;
  bool _clearingOcrCache = false;

  /// True when the user has explicitly entered edit mode (Replace / Clear).
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    // B1: When no key exists, edit mode starts enabled so the user can enter one.
    // When a key is set, _editMode starts false (view mode) and Save is a no-op.
    final state = ref.read(apiKeyProvider);
    _editMode = state is! ApiKeySet;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _editMode = true;
      _controller.clear();
      _errorText = null;
    });
    _focusNode.requestFocus();
  }

  void _cancelEditMode() {
    setState(() {
      _editMode = false;
      _controller.clear();
      _errorText = null;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  Future<void> _save() async {
    // Guard: save only works when the user is in explicit edit mode.
    // If the field shows "●●●●●●●●●●●●●●●●●●●●●●" (no edit), this is a no-op.
    if (!_editMode) return;

    setState(() {
      _saving = true;
      _errorText = null;
    });
    final notifier = ref.read(apiKeyProvider.notifier);
    final err = await notifier.save(_controller.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (err != null) {
        _errorText = err;
      } else {
        // Save succeeded — exit edit mode, clear field, go back to view mode.
        _editMode = false;
        _controller.clear();
      }
    });
    if (err == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key saved.')));
    }
  }

  Future<void> _clear() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    await ref.read(apiKeyProvider.notifier).clear();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editMode = false;
      _controller.clear();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('API key cleared.')));
  }

  @override
  Widget build(BuildContext context) {
    final apiKeyState = ref.watch(apiKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // BYOK cost notice.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'OCR usage is billed to your Mistral account. '
                    'Set a spending limit on mistral.ai.',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // API key section header.
          Text(
            'Mistral API Key',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your key is stored in Android secure storage and never sent to Brrk servers.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // ── P0-1 fix: view-only mode when key is set ──────────────────────
          // When in edit mode, the field is active and Save works.
          // When NOT in edit mode, the field is disabled and shows status only.
          if (apiKeyState is ApiKeySet && !_editMode) ...[
            // Key is set — show masked preview, not an editable field.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Credential is set',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          apiKeyState.masked,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _clear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _enterEditMode,
                    child: const Text('Replace'),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Edit mode or no key set — show editable field.
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              obscureText: _obscure,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: const OutlineInputBorder(),
                errorText: _errorText,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  tooltip: _obscure ? 'Show key' : 'Hide key',
                ),
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_editMode) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _cancelEditMode,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: (_editMode && !_saving) ? _save : null,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],

          // ── end P0-1 ───────────────────────────────────────────────────────
          const SizedBox(height: 16),

          // Mistral API key guidance.
          Text(
            'Get a Mistral API key from the Mistral Console:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () =>
                launchUrl(Uri.parse('https://console.mistral.ai/')),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open Mistral Console'),
          ),
          Text(
            "Create/sign in to a Mistral account, then create an API key from the API Keys section.",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Text(
            'Before using OCR or vocabulary lookup, review how Brrk sends data to Mistral:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _openUrl(_privacyPolicyUrl),
                icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                label: const Text('Privacy Policy'),
              ),
              TextButton.icon(
                onPressed: () => _openUrl(_termsOfUseUrl),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Terms of Use'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── P0-4: OCR data-transfer disclosure ────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Data sent to Mistral OCR',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Brrk sends selected image or PDF content directly to '
                  'Mistral OCR using your API key to perform OCR. Brrk does '
                  'not send this content to the Brrk developer.',
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                ),
              ],
            ),
          ),

          // ── end P0-4 ───────────────────────────────────────────────────────
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 24),

          // Reading Appearance section.
          Text(
            'Reading Appearance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Controls how text appears in PDFs and paper pages.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          const ReadingAppearanceControls(),

          // ── OCR Cache section ──────────────────────────────────────────
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 24),

          Text('OCR Cache', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Cached OCR results allow offline re-renders without repeating API calls.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _clearingOcrCache
                ? null
                : () => _confirmClearOcrCache(context),
            icon: _clearingOcrCache
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_sweep),
            label: Text(_clearingOcrCache ? 'Clearing…' : 'Clear OCR Cache'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
          ),

          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 24),
          Text('Legal', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Public policy pages for Google Play review and user reference.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openUrl(_privacyPolicyUrl),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Privacy Policy'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openUrl(_termsOfUseUrl),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Terms of Use'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearOcrCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear OCR cache?'),
        content: const Text(
          'This removes cached OCR results only. Books, pages, PDFs, notes, '
          'and saved Markdown are kept. Future OCR may call Mistral again and '
          'may count toward your Mistral billing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _clearOcrCache();
    }
  }

  Future<void> _clearOcrCache() async {
    setState(() => _clearingOcrCache = true);
    try {
      final count = await storage.clearOcrCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR cache cleared: $count entries removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cache clear failed: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _clearingOcrCache = false);
    }
  }
}
