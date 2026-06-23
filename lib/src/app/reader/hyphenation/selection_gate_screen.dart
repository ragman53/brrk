// SPDX-License-Identifier: MIT
//
// Phase B soft-hyphen selection gate screen.
//
// THIS IS A SPIKE-ONLY SCREEN, NOT PRODUCTION HYPHENATION.
// It exists solely to manually test how Flutter selection behaves
// when display text contains U+00AD soft hyphens. It must not be
// integrated into the Paper/PDF readers or be used to drive real
// Add Note / vocabulary / Rust / OCR / storage writes.
//
// See FEAT-SPEC.md §11 for the mandatory selection gate that precedes
// any production hyphenation work.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../reading_appearance.dart'
    show brrkSerifFontFamily, brrkSerifFontFallback;
import 'academic_selectable_text.dart';
import 'reader_text_layout_spec.dart';
import 'soft_hyphen_mapping.dart';

/// Debug-only soft-hyphen selection gate.
///
/// Exposes two narrow-width test surfaces (one `SelectableText` and one
/// `Markdown(selectable: true)`) using hand-authored U+00AD
/// opportunities in fixed English words. Hard-hyphen and apostrophe
/// examples are kept unchanged for regression comparison.
class SelectionGateScreen extends StatefulWidget {
  const SelectionGateScreen({super.key});

  @override
  State<SelectionGateScreen> createState() => _SelectionGateScreenState();
}

class _SelectionGateScreenState extends State<SelectionGateScreen> {
  /// Canonical source strings. These are the strings the readers would
  /// actually store and operate on. They contain no soft hyphens.
  static const _sourceForSelectable = [
    'investigation philosophical conversation',
    'rabbit-hole self-conscious don\'t',
  ];

  /// Display strings with hand-authored U+00AD soft hyphens inserted
  /// only in eligible English words. The unchanged set is the
  /// regression check.
  static const _displayForSelectableLine0 =
      'inv\u00ADestigation phi\u00ADlos\u00ADophi\u00ADcal con\u00ADver\u00ADsa\u00ADtion';
  static const _displayForSelectableLine1 = 'rabbit-hole self-conscious don\'t';

  static const _displayForSelectableJoined =
      '$_displayForSelectableLine0\n\n$_displayForSelectableLine1';

  static const _displayForMarkdown =
      'inv\u00ADestigation phi\u00ADlos\u00ADophi\u00ADcal con\u00ADver\u00ADsa\u00ADtion\n\nrabbit-hole self-conscious don\'t';

  /// Forced visual proof: this word should wrap as `philo-` / `sophical`
  /// in the narrow proof boxes if Flutter honors U+00AD as a line-break
  /// opportunity with a visible line-end hyphen.
  static const _forcedWrapDisplay = 'philo\u00ADsophical';

  static const _forcedWrapStyle = TextStyle(fontSize: 22, height: 1.25);

  // Selection state for the SelectableText surface.
  final _stFocusNode = FocusNode();
  TextSelection? _stDisplaySelection;

  // Selection state for the Markdown surface.
  String _mdLastText = '';
  TextSelection? _mdDisplaySelection;

  // Selection state for forced visual proof surfaces.
  TextSelection? _forcedStSelection;
  String _forcedMdLastText = '';
  TextSelection? _forcedMdSelection;

  // Selection state for the decorative overlay proof surface.
  TextSelection? _overlaySelection;

  @override
  void dispose() {
    _stFocusNode.dispose();
    super.dispose();
  }

  /// Builds the spike-only display-to-canonical mapping for the
  /// SelectableText source. Each line maps independently so offsets
  /// are per-line and a user selecting across newlines would fall
  /// back to the unchanged string (which is what the FEAT-SPEC gate
  /// tests anyway).
  List<SoftHyphenMapping> _selectableMappings() {
    const sources = _sourceForSelectable;
    return [
      for (var i = 0; i < sources.length; i++)
        SoftHyphenMapping.fromInsertionOffsets(
          sources[i],
          insertBeforeSourceBoundary: _insertionOffsetsFor(
            sources[i],
            index: i,
          ),
        ),
    ];
  }

  /// Returns the canonical source boundary offsets at which a soft
  /// hyphen should appear in the display version, for the i-th line.
  /// For now this is hand-authored to match the gate examples.
  List<int> _insertionOffsetsFor(String source, {required int index}) {
    if (index == 0) {
      // inv|estigation  phi|los|ophi|cal  con|ver|sa|tion
      return _asciiOffsetsAfter(source, const [
        'inv',
        'phi',
        'los',
        'ophi',
        'con',
        'ver',
        'sa',
      ]);
    }
    return const <int>[];
  }

  /// Computes the offsets in [source] that come immediately after the
  /// end of each fragment in [fragments] (UTF-16 boundaries). Used to
  /// build hand-authored insertion sets without leaking the test
  /// strings.
  List<int> _asciiOffsetsAfter(String source, List<String> fragments) {
    final out = <int>[];
    var cursor = 0;
    for (final frag in fragments) {
      final found = source.indexOf(frag, cursor);
      if (found < 0) continue;
      cursor = found + frag.length;
      out.add(cursor);
    }
    return out;
  }

  void _onStSelectionChanged(TextSelection sel, SelectionChangedCause? _) {
    setState(() => _stDisplaySelection = sel);
  }

  void _onMdSelectionChanged(
    String? text,
    TextSelection sel,
    SelectionChangedCause? _,
  ) {
    setState(() {
      _mdLastText = text ?? '';
      _mdDisplaySelection = sel;
    });
  }

  void _onForcedStSelectionChanged(
    TextSelection sel,
    SelectionChangedCause? _,
  ) {
    setState(() => _forcedStSelection = sel);
  }

  void _onForcedMdSelectionChanged(
    String? text,
    TextSelection sel,
    SelectionChangedCause? _,
  ) {
    setState(() {
      _forcedMdLastText = text ?? '';
      _forcedMdSelection = sel;
    });
  }

  void _onOverlaySelectionChanged(
    TextSelection sel,
    SelectionChangedCause? cause,
  ) {
    setState(() => _overlaySelection = sel);
  }

  Future<void> _copy(String label, String value) async {
    await copyRawToClipboard(value);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied ($label)')));
  }

  Widget _stObservation() {
    final mappings = _selectableMappings();
    final sel = _stDisplaySelection;
    const display = _displayForSelectableJoined;
    final blocks = <String>[
      _displayForSelectableLine0,
      _displayForSelectableLine1,
    ];
    String? perLineLabel;
    String perLineDisplay = '';
    String perLineCanonical = '';
    if (sel != null && !sel.isCollapsed) {
      final start = sel.start.clamp(0, display.length);
      final end = sel.end.clamp(start, display.length);
      var running = 0;
      for (var i = 0; i < blocks.length; i++) {
        final block = blocks[i];
        final blockStart = running;
        final blockEnd = running + block.length;
        if (start >= blockStart && end <= blockEnd && start < end) {
          perLineLabel = 'line $i';
          perLineDisplay = display.substring(start, end);
          final localStart = start - blockStart;
          final localEnd = end - blockStart;
          final localSel = TextSelection(
            baseOffset: localStart,
            extentOffset: localEnd,
          );
          perLineCanonical = mappings[i].sourceSubstring(localSel);
          break;
        }
        running = blockEnd + 2; // '\n\n'
      }
    }
    return _ObservationPanel(
      title: 'SelectableText observation',
      surfaceText: display,
      selection: sel,
      perLineLabel: perLineLabel,
      displaySubstring: perLineDisplay.isEmpty ? null : perLineDisplay,
      canonicalSubstring: perLineCanonical.isEmpty ? null : perLineCanonical,
      simulatedAddNote: perLineCanonical.isEmpty
          ? null
          : 'Add Note would store: "$perLineCanonical"',
      simulatedLookUp: perLineCanonical.isEmpty
          ? null
          : 'Look up would send: "$perLineCanonical"',
      onCopyDisplay: perLineDisplay.isEmpty
          ? null
          : () => _copy('SelectableText display', perLineDisplay),
      onCopyCanonical: perLineCanonical.isEmpty
          ? null
          : () => _copy('SelectableText canonical', perLineCanonical),
    );
  }

  Widget _mdObservation() {
    return _displayTextObservation(
      title: 'Markdown observation',
      display: _mdLastText,
      selection: _mdDisplaySelection,
      copyLabel: 'Markdown',
    );
  }

  Widget _forcedStObservation() {
    return _displayTextObservation(
      title: 'Forced SelectableText observation',
      display: _forcedWrapDisplay,
      selection: _forcedStSelection,
      copyLabel: 'Forced SelectableText',
    );
  }

  Widget _forcedMdObservation() {
    return _displayTextObservation(
      title: 'Forced Markdown observation',
      display: _forcedMdLastText,
      selection: _forcedMdSelection,
      copyLabel: 'Forced Markdown',
    );
  }

  /// Decorative overlay proof observation. The same canonical
  /// `sourceSubstring` mapping is applied so the user can confirm the
  /// overlay's selectable text is still canonically addressable.
  Widget _overlayObservation() {
    const display = _forcedWrapDisplay;
    const source = 'philosophical';
    final sel = _overlaySelection;
    String displaySub = '';
    String canonicalSub = '';
    String simulatedAddNote = '';
    String simulatedLookUp = '';
    if (sel != null && !sel.isCollapsed) {
      final start = sel.start.clamp(0, display.length);
      final end = sel.end.clamp(start, display.length);
      displaySub = display.substring(start, end);
      final mapping = SoftHyphenMapping.fromDisplayText(display);
      final localSel = TextSelection(baseOffset: start, extentOffset: end);
      canonicalSub = mapping.sourceSubstring(localSel);
      if (canonicalSub.isNotEmpty) {
        simulatedAddNote = 'Add Note would store: "$canonicalSub"';
        simulatedLookUp = 'Look up would send: "$canonicalSub"';
      }
    }
    return _ObservationPanel(
      title: 'Decorative overlay observation',
      surfaceText: display,
      selection: sel,
      perLineLabel: null,
      displaySubstring: displaySub.isEmpty ? null : displaySub,
      canonicalSubstring: canonicalSub.isEmpty ? null : canonicalSub,
      simulatedAddNote: simulatedAddNote.isEmpty ? null : simulatedAddNote,
      simulatedLookUp: simulatedLookUp.isEmpty ? null : simulatedLookUp,
      onCopyDisplay: displaySub.isEmpty
          ? null
          : () => _copy('Overlay display', displaySub),
      onCopyCanonical: canonicalSub.isEmpty || canonicalSub == source
          ? null
          : () => _copy('Overlay canonical', canonicalSub),
    );
  }

  Widget _displayTextObservation({
    required String title,
    required String display,
    required TextSelection? selection,
    required String copyLabel,
  }) {
    final sel = selection;
    String displaySub = '';
    String canonicalSub = '';
    String simulatedAddNote = '';
    String simulatedLookUp = '';
    if (sel != null && !sel.isCollapsed) {
      final start = sel.start.clamp(0, display.length);
      final end = sel.end.clamp(start, display.length);
      displaySub = display.substring(start, end);
      final mapping = SoftHyphenMapping.fromDisplayText(display);
      final localSel = TextSelection(baseOffset: start, extentOffset: end);
      canonicalSub = mapping.sourceSubstring(localSel);
      if (canonicalSub.isNotEmpty) {
        simulatedAddNote = 'Add Note would store: "$canonicalSub"';
        simulatedLookUp = 'Look up would send: "$canonicalSub"';
      }
    }
    return _ObservationPanel(
      title: title,
      surfaceText: display,
      selection: sel,
      perLineLabel: null,
      displaySubstring: displaySub.isEmpty ? null : displaySub,
      canonicalSubstring: canonicalSub.isEmpty ? null : canonicalSub,
      simulatedAddNote: simulatedAddNote.isEmpty ? null : simulatedAddNote,
      simulatedLookUp: simulatedLookUp.isEmpty ? null : simulatedLookUp,
      onCopyDisplay: displaySub.isEmpty
          ? null
          : () => _copy('$copyLabel display', displaySub),
      onCopyCanonical: canonicalSub.isEmpty
          ? null
          : () => _copy('$copyLabel canonical', canonicalSub),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soft-hyphen selection gate')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('SelectableText surface'),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 280,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: SelectableText(
                    _displayForSelectableJoined,
                    key: const Key('gate-selectable'),
                    focusNode: _stFocusNode,
                    onSelectionChanged: _onStSelectionChanged,
                    showCursor: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _stObservation(),
            const SizedBox(height: 24),
            const _SectionLabel('Markdown surface'),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 280,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Markdown(
                    key: const Key('gate-markdown'),
                    data: _displayForMarkdown,
                    selectable: true,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onSelectionChanged: _onMdSelectionChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _mdObservation(),
            const SizedBox(height: 24),
            const _SectionLabel('Native U+00AD proof — expected to fail'),
            const SizedBox(height: 4),
            const Text(
              'These orange boxes show Flutter\'s native soft-hyphen '
              'rendering. On the tested Android device they wrap but do '
              'not draw a visible hyphen. That is expected now. Scroll '
              'to the indigo “Decorative overlay proof” below for the '
              'new visual-hyphen experiment.',
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 104,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepOrange),
                  ),
                  child: SelectableText(
                    _forcedWrapDisplay,
                    key: const Key('gate-forced-selectable'),
                    style: _forcedWrapStyle,
                    onSelectionChanged: _onForcedStSelectionChanged,
                    showCursor: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _forcedStObservation(),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 104,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepOrange),
                  ),
                  child: Markdown(
                    key: const Key('gate-forced-markdown'),
                    data: _forcedWrapDisplay,
                    selectable: true,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    styleSheet: MarkdownStyleSheet(p: _forcedWrapStyle),
                    onSelectionChanged: _onForcedMdSelectionChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _forcedMdObservation(),
            const SizedBox(height: 24),
            const _SectionLabel('Decorative overlay proof'),
            const SizedBox(height: 4),
            const Text(
              'Same forced word rendered through AcademicSelectableText. '
              'Expect a visible U+2010 hyphen at the right edge of the '
              'first line. Selection still maps to the canonical '
              '"philosophical".',
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 104,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.indigo),
                  ),
                  child: AcademicSelectableText(
                    spec: const ReaderTextLayoutSpec(
                      displayText: _forcedWrapDisplay,
                      resolvedTextStyle: TextStyle(
                        fontSize: 22,
                        height: 1.25,
                        fontFamily: brrkSerifFontFamily,
                        fontFamilyFallback: brrkSerifFontFallback,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    sourceText: 'philosophical',
                    onSelectionChanged: _onOverlaySelectionChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _overlayObservation(),
            const SizedBox(height: 24),
            const _SectionLabel('Notes'),
            const SizedBox(height: 4),
            const Text(
              'This is a debug-only selection gate. It does not write to '
              'app storage, Rust, Mistral, or notes. Use Copy display '
              'and Copy canonical to compare what the system reports '
              'against the expected canonical text.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _ObservationPanel extends StatelessWidget {
  const _ObservationPanel({
    required this.title,
    required this.surfaceText,
    required this.selection,
    required this.perLineLabel,
    required this.displaySubstring,
    required this.canonicalSubstring,
    this.simulatedAddNote,
    this.simulatedLookUp,
    this.onCopyDisplay,
    this.onCopyCanonical,
  });

  final String title;
  final String surfaceText;
  final TextSelection? selection;
  final String? perLineLabel;
  final String? displaySubstring;
  final String? canonicalSubstring;
  final String? simulatedAddNote;
  final String? simulatedLookUp;
  final VoidCallback? onCopyDisplay;
  final VoidCallback? onCopyCanonical;

  @override
  Widget build(BuildContext context) {
    final sel = selection;
    final collapsed = sel == null || sel.isCollapsed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('surface length: ${surfaceText.length}'),
          if (sel != null)
            Text(
              'selection: start=${sel.start} end=${sel.end} '
              'collapsed=$collapsed',
            ),
          if (perLineLabel != null) Text('selection range: $perLineLabel'),
          if (displaySubstring != null)
            Text('display substring: "$displaySubstring"'),
          if (canonicalSubstring != null)
            Text('canonical substring: "$canonicalSubstring"'),
          if (simulatedAddNote != null) Text(simulatedAddNote!),
          if (simulatedLookUp != null) Text(simulatedLookUp!),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: onCopyDisplay,
                child: const Text('Copy display'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onCopyCanonical,
                child: const Text('Copy canonical'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
