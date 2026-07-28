# FIX.md — OCR Reader UI Performance Fix

## 1. Purpose

Brrk の Paper / PDF Reader で、OCR 後の長文を表示・スクロール・選択すると UI が重くなり、フレーム落ちやカクつきが発生する問題を修正する。

この修正は、既存の読書機能を簡略化して速度を得るものではない。特に、Academic mode の Emergency word breaking、実際の折り返し位置にだけ表示される装飾ハイフン、canonical text と display text の offset mapping、Copy / Add Note / Look up の整合性を維持したまま、同じ文章に対する不要な再解析・再変換・再レイアウトを止める。

対象 baseline:

```text
repository: ragman53/brrk
branch: main
baseline commit: 83204fc64ecf726b1b378708bb83f3bf73dacf86
```

この文書は実装指示書である。実装中に本書と `SPEC.md` または `REVIEW.md` が競合する場合、既存の表示・選択・canonical mapping 契約を優先し、勝手に製品仕様を変更しないこと。

---

## 2. Confirmed scope

主な対象ファイル:

```text
lib/src/app/reader/brrk_reader_page.dart
lib/src/app/reader/reader_markdown_plan.dart
lib/src/app/reader/reader_paragraph_layout.dart
lib/src/app/reader/emergency_word_breaker.dart
lib/src/app/reader/hyphenation/hyphenated_text.dart
lib/src/app/reader/hyphenation/academic_selectable_text.dart
lib/src/app/reader/hyphenation/hyphen_overlay_layout.dart
lib/src/app/pdf_viewer_screen.dart
lib/src/app/paper_book/paper_book_page_view.dart
lib/src/app/reading_appearance.dart
```

主なテスト対象:

```text
test/brrk_reader_page_test.dart
test/pdf_viewer_screen_test.dart
test/reader_paragraph_layout_test.dart
test/emergency_word_breaker_test.dart
test/academic_selectable_text_test.dart
test/visible_hyphen_painter_test.dart
test/renderer_integration_test.dart
```

必要に応じて Paper Reader の既存 selection / note / vocabulary テストも更新する。

Rust、FRB、OCR API、storage format、Mistral response parser は今回の性能問題の主因ではないため、原則として変更しない。

---

## 3. Symptoms

実機で特に問題が出やすい操作:

- OCR 結果を開いた直後の初回表示
- 長いページのスクロール
- 単語の長押し、ダブルタップ、選択ハンドル移動
- 選択ストリップの表示・非表示
- ノートの非同期ロード完了
- ページ移動
- font size slider のドラッグ
- Academic mode の長い英単語を多く含む文章
- Markdown table、link、emphasis 等を含み fallback renderer に入る PDF ページ

静的解析上、同じ OCR 文章が変化していないにもかかわらず、親の `setState()` や Provider 更新により reader subtree が再構築され、その過程で Markdown planning、Emergency word breaking、display-to-source mapping の生成、SelectableText の更新、Academic overlay layout が繰り返される可能性がある。

---

## 4. Root causes to fix

### 4.1 Markdown plan is recomputed from `build()`

`BrrkReaderPage` の plan が getter 経由で `planReaderMarkdown(widget.markdown)` を呼ぶため、reader が再 build されるたびに Markdown 全文を再走査する。

期待する契約:

```text
同じ markdown + 同じ planOverride
→ 同じ ReaderMarkdownPlan を再利用

markdown または planOverride が変更
→ その時だけ再計算
```

### 4.2 Paragraph display preparation is recomputed from `build()`

`BrrkReaderParagraph.build()` が毎回 `ReaderParagraphLayout.render()` を呼び、Academic mode では `EmergencyWordBreaker.breakText()` と `HyphenatedText` mapping 生成を再実行する。

Emergency word breaking の候補位置は paragraph text と layout mode で決まり、font size、density、palette、viewport width では変化しない。これらの見た目設定が変わっただけで break opportunity を再生成してはならない。

期待する契約:

```text
同じ canonical paragraph text + Academic mode
→ HyphenatedText を再利用

font size / density / palette / viewport width の変更
→ Flutter text layout と overlay geometry は必要に応じて更新
→ EmergencyWordBreaker.breakText() は再実行しない

Natural mode
→ EmergencyWordBreaker.breakText() を呼ばない
```

### 4.3 Selection-only state rebuilds the complete reader

PDF と Paper の selection callback が親 `State` の `setState()` を呼び、selected strip のためだけに reader 本体まで rebuild する。

選択ハンドル移動中は callback が連続発火するため、reader 本体を同じ頻度で rebuild すると jank が発生する。

期待する契約:

```text
selection / lookup candidate だけが変更
→ action strip と selection-dependent controls だけ更新
→ BrrkReaderPage は rebuild しない
```

### 4.4 Note state rebuilds the complete reader

PDF note の非同期ロード、Paper note の追加・削除など、本文と無関係な state 更新で reader subtree が rebuild される。

期待する契約:

```text
notes だけが変更
→ note chip area だけ更新
→ OCR text renderer は再解析・再変換しない
```

### 4.5 Font slider persists on every drag tick

font size slider の `onChanged` ごとに Provider state 更新と SharedPreferences write が発生する。文字レイアウト更新自体は必要だが、永続化 I/O はドラッグ中の各 tick で行う必要がない。

期待する契約:

```text
onChanged
→ in-memory preview only

onChangeEnd または短い debounce 後
→ SharedPreferences に一度保存
```

---

## 5. Non-negotiable reader invariants

以下は性能改善より優先される。ひとつでも壊れる修正は採用しない。

### 5.1 Natural mode

- `TextAlign.start` を維持する。
- Emergency word breaking を実行しない。
- selectable text に `U+00AD` を挿入しない。
- canonical source text と表示文字列が一致する。
- Copy / Add Note / Look up の既存挙動を維持する。

### 5.2 Academic mode

- `TextAlign.justify` を維持する。
- `[A-Za-z]+` の eligible long word に対する deterministic Emergency word breaking を維持する。
- minimum word length 7 を維持する。
- prefix / suffix を最低3文字保持する。
- `3 <= offset <= n - 3` のすべての eligible internal boundary に `U+00AD` opportunity を挿入する。
- Flutter が実際の折り返し位置を決定する。
- 実際に `U+00AD` で折り返された位置にだけ装飾ハイフンを表示する。
- 装飾ハイフンは selectable text、Copy、semantics、Add Note、Look up、storage、export に含めない。
- one primary `SelectableText` per paragraph の構造を維持する。
- custom line composer、manual newline、line-per-widget implementation を導入しない。

### 5.3 Protected tokens

以下へ Emergency word breaking を挿入しない既存契約を維持する。

- short words
- Japanese / CJK
- mixed-script tokens
- apostrophe words
- hard-hyphen compounds
- URLs
- email addresses
- file paths
- Markdown link / image destinations
- inline code
- fenced code
- identifiers containing `_`, `/`, `\\`, `@`, `:`
- numeric tokens

### 5.4 Canonical mapping

必須 selection flow:

```text
display TextSelection
→ display-to-source mapping
→ canonical raw selection
→ Add Note
→ vocabularyCandidateFromSelection
→ canonical lookup text and offsets
```

次を維持する。

- `U+00AD` は Rust、storage、notes、vocabulary、manual Markdown、export、logs に送らない。
- native prose の exact source offsets を維持する。
- fallback Markdown の source offsets は推測せず `null` を維持する。
- fallback callback context は rendered plain text と一致させる。
- Markdown source offset と rendered text offset を混在させない。
- `SelectionChangedCause` を失わない。

### 5.5 Existing visible-hyphen architecture

以下の責務分離を維持する。

```text
EmergencyWordBreaker
→ break opportunities + canonical mapping

AcademicSelectableText
→ selectable surface + cached overlay layout ownership

HyphenOverlayLayoutEngine
→ actual break detection + precomputed stroke geometry

VisibleHyphenPainter
→ precomputed stroke drawing only
```

`VisibleHyphenPainter.paint()` に TextPainter、Markdown parse、soft-hyphen scan、selection mapping を戻してはならない。

---

## 6. Explicitly forbidden fixes

速度改善を理由に次を行ってはならない。

- Academic mode を削除、非表示、実質無効化する。
- Academic mode を単なる `TextAlign.justify` に後退させる。
- visible decorative hyphen を削除する。
- eligible soft-hyphen insertion boundary を間引く。
- minimum word length、prefix、suffix の仕様を変更する。
- `EmergencyWordBreaker` を別アルゴリズムへ置換する。
- visible `-` または `U+2010` を selectable text に直接挿入する。
- 手動改行で折り返し位置を固定する。
- paragraph を visual line ごとの widget に分割する。
- custom text layout / custom selection engine を作る。
- selection callback を粗く debounce してハンドル追従を壊す。
- selection offset を近似または再検索で推測する。
- Paper と PDF に別々の selection / vocabulary アルゴリズムを作る。
- Rust 側で Flutter text layout を再構築する。
- OCR Markdown の内容を性能目的で破壊的に変更する。
- `.pub-cache` を直接編集する。
- unbounded global cache を追加する。
- 初回 patch で `SingleChildScrollView + Column` を全面的に Sliver 化する。
- 初回 patch で block-level Markdown renderer を新規実装する。

Sliver 化や renderer 再設計は、以下の安全な再計算抑制を実装・計測した後でも問題が残る場合の別タスクとする。

---

## 7. Implementation strategy

変更は以下の順序で行う。各 phase はテストが通った状態で完了させる。

## Phase 0 — Baseline and instrumentation

### Goal

推測だけで最適化せず、再計算回数と frame behavior の baseline を得る。

### Required checks

Profile mode の実機で次を確認する。

```text
1. Paper Natural page open
2. Paper Academic page open
3. PDF native prose page open
4. PDF legacy Markdown page open
5. steady-state scrolling
6. long press
7. double tap
8. selection handle dragging
9. selection clear
10. note async load / note add
11. font slider dragging
12. page navigation
```

テスト用 seam または debug/profile instrumentation で最低限次の呼び出し回数を観測する。

```text
planReaderMarkdown
EmergencyWordBreaker.breakText
HyphenOverlayLayoutEngine.compute
BrrkReaderPage.build
BrrkReaderParagraph.build
```

Instrumentation は document content をログ出力しない。release build に不要なログや counters を残さない。

### Baseline report

実装前に少なくとも次を記録する。

- 対象端末
- build mode
- test paragraph length / block count
- Natural / Academic
- native / fallback strategy
- selection handle drag 中の planner / breaker / overlay compute 回数
- frame timeline 上の大きな build / layout spike

任意の絶対 FPS 値だけを成功条件にしない。端末差が大きいため、同じ操作で不要な同期処理が消えたことを主な判定基準とする。

---

## Phase 1 — Cache `ReaderMarkdownPlan`

### Goal

同じ Markdown に対する `planReaderMarkdown()` の build-time 再実行を止める。

### Required implementation

`_BrrkReaderPageState` が resolved plan を保持する。

概念形:

```dart
late ReaderMarkdownPlan _resolvedPlan;

ReaderMarkdownPlan _resolvePlan() =>
    widget.planOverride ?? planReaderMarkdown(widget.markdown);

@override
void initState() {
  super.initState();
  _resolvedPlan = _resolvePlan();
}

@override
void didUpdateWidget(covariant BrrkReaderPage oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.markdown != widget.markdown ||
      oldWidget.planOverride != widget.planOverride) {
    _resolvedPlan = _resolvePlan();
  }
}
```

実際の実装では test seam と diagnostic behavior を維持する。

### Invalidation key

再計算条件は次だけとする。

```text
markdown changed
OR
planOverride changed
```

次では plan を再計算しない。

- selection state
- notes
- palette
- font size
- density
- layout mode
- scroll offset
- viewport height

Reader strategy は Markdown syntax で決まり、appearance では変化しない。

### Required tests

- initial build で planner が1回だけ実行される。
- parent rebuild で同じ Markdown を渡しても追加実行されない。
- selection-related parent update で追加実行されない。
- appearance change で追加実行されない。
- Markdown change でちょうど1回再実行される。
- `planOverride` change でちょうど1回更新される。
- native / legacy strategy と reason が変わらない。

必要なら `@visibleForTesting` の小さな planner seam を追加してよい。ただし production 用の抽象化層や service を増やさない。

---

## Phase 2 — Cache paragraph text preparation

### Goal

同じ paragraph に対する Emergency word breaking と display-to-source mapping の再生成を止める。

### Design rule

paragraph preparation を次の2種類に分ける。

```text
A. text-dependent preparation
   - canonical text
   - layout mode
   - HyphenatedText / identity mapping
   - overlayEnabled

B. appearance-dependent presentation
   - TextStyle
   - TextAlign
   - font size
   - density
   - palette
```

A は paragraph text または layout mode が変わった場合だけ再計算する。B は build ごとに安価に解決してよい。

### Preferred local structure

`BrrkReaderParagraph` を StatefulWidget にし、paragraph widget 単位で prepared text を保持する。

例となる state key:

```text
canonicalText
layoutMode
```

global cache は使わない。page navigation で破棄される widget-local cache を優先し、document 全体を保持し続けるメモリ増加を避ける。

### Academic mode contract

同じ canonical text に対して:

```text
first Academic build
→ EmergencyWordBreaker.breakText() once

selection-only rebuild
→ zero additional calls

scroll
→ zero additional calls

font size change
→ zero additional breakText calls
→ overlay layout may recompute because line breaks changed

viewport width / orientation change
→ zero additional breakText calls
→ overlay layout may recompute because line breaks changed

palette-only change
→ zero additional breakText calls
```

Natural → Academic または Academic → Natural へ切り替えた時だけ prepared text を更新する。

### Natural mode identity path

Natural mode では `EmergencyWordBreaker.breakText()` を呼ばない。

現在の identity mapping 生成が paragraph 長に比例する List allocation を行う場合、次のいずれかを採用してよい。

1. 最初の patch では prepared result 自体を cache して再 allocation を止める。
2. focused tests を追加した上で `HyphenatedText.identity(sourceText)` のような identity fast path を追加する。

identity fast path を追加する場合、次を満たすこと。

- `sourceText == displayText`
- `mapDisplayBoundaryToSource(offset) == clamped offset`
- reversed selection を保持する。
- collapsed / invalid selection の既存 behavior を維持する。
- Academic mapping の List behavior を変更しない。
- public document model や一般 mapping framework に拡張しない。

最初の performance patch を identity fast path の完成に依存させなくてもよい。安全な cache を先に入れる。

### Stable keys

`_NativeReaderBody` の paragraph / heading key は page 内で安定している必要がある。

現在の block index key を維持し、同じ page / same plan 内の parent rebuild で paragraph State が失われないようにする。

Markdown が変わり blocks の意味が変わる場合は、古い prepared text を誤再利用しない。必要であれば key に block type と stable source position を含める。ただし paragraph text 自体を巨大な key string として複製しない。

### Required tests

- Academic paragraph initial build で `breakText()` が1回。
- same text + same mode の rebuild で追加実行なし。
- font size / density / palette change で追加実行なし。
- width change で追加実行なし。
- text change で1回再実行。
- Natural → Academic で1回実行。
- Academic → Natural で canonical identity に戻る。
- Natural mode は `breakText()` 0回。
- all existing EmergencyWordBreaker cases unchanged。
- display-to-source mapping unchanged。
- visible overlay still receives the same display text。

---

## Phase 3 — Isolate selection UI state from reader rendering

### Goal

selection handle movement が OCR reader 本体を rebuild しないようにする。

### State shape

selection-dependent data をひとつの immutable local state にまとめる。

概念形:

```dart
class ReaderActionState {
  final String selectedText;
  final String canonicalContext;
  final int? selectionStart;
  final int? selectionEnd;
  final String? lookupText;
  final int? lookupStart;
  final int? lookupEnd;
  final SelectionChangedCause? cause;
}
```

実装名は任意だが、Paper と PDF で意味の異なる offset を混在させないこと。

### Preferred state mechanism

新しい global Provider、stream、event bus は追加しない。

次のいずれかの小さな local mechanism を使用する。

- `ValueNotifier<ReaderActionState?>`
- reader viewport 専用の小さな StatefulWidget
- selection strip 専用 controller owned by the current screen

選択 callback は local state を更新し、次だけを再 build する。

- selected strip
- Look up button enabled state
- Add Note button enabled state
- selection-dependent note action

`BrrkReaderPage`、paragraph widgets、MarkdownBody は selection-only update で build しない。

### PDF requirements

- `_handleReaderSelection` の candidate recovery behavior を維持する。
- fallback context contract を維持する。
- `sourceStart` / `sourceEnd` を推測しない。
- page change で selection state を clear する。
- manual Markdown change で selection state を clear する。
- Look up 開始後の clear behavior を維持する。
- Add Note が現在の raw selection と context を受け取る。

### Paper requirements

- UTF-16 → UTF-8 byte offset 変換の結果を維持する。
- 可能であれば selection handle 移動中には UTF-8 encode を繰り返さず、Add Note 実行時に変換する。
- 変換タイミングを変更する場合も exact page-source offset が証明された native selection だけを変換する。
- existing Note の start/end storage contract を変更しない。
- Look up は canonical UTF-16 candidate を使用し、Rust 呼び出し直前の既存 conversion contract を維持する。

### No-op update guard

selection clear event が来た時、すでに state が空なら notifier / widget update を発生させない。

同一 selection state が連続通知された場合も、値が等しいなら不要な UI rebuild を避けてよい。ただし selection handle の正しい追従を阻害する debounce は入れない。

### Required tests

- selection event で action strip は更新される。
- reader build count は増えない。
- selection handle 相当の連続 event でも reader build count は増えない。
- selection clear で strip が消える。
- already-cleared state への null event は no-op。
- Add Note / Look up が最新 selection を使う。
- double tap / long press / drag cause を維持する。
- Paper canonical mapping と UTF-8 note offset が維持される。
- PDF fallback lookup regression test が維持される。

---

## Phase 4 — Isolate note state from reader rendering

### Goal

notes の非同期ロード・追加・削除による OCR reader rebuild を止める。

### PDF

`_loadPdfNotes()` 完了時の state 更新は note chip area だけへ伝える。

ページ移動時は:

```text
page Markdown change
→ reader updates once

note loading start / finish
→ note area only
```

同じ page の note load 完了で `planReaderMarkdown()`、`breakText()`、overlay compute が増えないこと。

### Paper

note list 更新時は note chip area を更新し、同じ page text の paragraph preparation を無効化しない。

### Required tests

- PDF Markdown load 後の note load completion で planner count が増えない。
- note add / delete で breaker count が増えない。
- Paper note update で prepared paragraph cache が保持される。
- note chip content と actions は正しく更新される。

---

## Phase 5 — Separate font preview from persistence

### Goal

font slider drag 中の SharedPreferences write を止める。

### Required behavior

- slider の visual preview は即時反映する。
- `onChangeEnd` または 150–300 ms 程度の persistence debounce で最終値を保存する。
- app 終了直前でも最終値が失われない設計にする。
- density、palette、layout mode の discrete control は現在どおり即時保存してよい。
- slider drag 中に複数の concurrent SharedPreferences writes を作らない。

### Important

font size が変われば Flutter の text layout と Academic overlay geometry は変わるため、その再計算は正しい。止める対象は Markdown planning、Emergency word breaking、canonical mapping 再生成、過剰な persistence I/O である。

### Required tests

- multiple `onChanged` 相当 update で in-memory state は追従する。
- persistence は drag completion または debounce 後に一度だけ行われる。
- reload 後に最終値が復元される。
- font size 12 / 17 / 24 / 32 で visible hyphen position と selection が回帰しない。

---

## 8. Existing overlay cache requirements

`AcademicSelectableText` の `_HyphenOverlayCacheKey` と `HyphenOverlayLayoutEngine` は、実際の line layout inputs が変わった場合に overlay geometry を再計算するためのものとして維持する。

期待する compute behavior:

```text
initial Academic layout
→ compute once per paragraph

steady scroll
→ no compute

selection-only update
→ no compute

note-only update
→ no compute

same-width parent rebuild
→ no compute

font size change
→ compute

density / line height change
→ compute

text scale change
→ compute

viewport width / orientation change
→ compute

paragraph display text change
→ compute
```

Overlay cache を無理に永続化または document-global 化しない。widget-local cache で十分である。

Painter は引き続き precomputed strokes だけを描画する。

---

## 9. Legacy Markdown fallback

PDF OCR Markdown は table、link、emphasis、list、quote 等を含むことがあるため、`LegacyMarkdownPlan` と patched `flutter_markdown` selection callback contract を維持する。

今回の initial fix では次を行う。

- Markdown strategy planning を cache する。
- selection-only / note-only update から fallback MarkdownBody を分離する。
- rendered plain text callback を維持する。
- selection callback ごとに `TextSpan.toPlainText()` を再実行しない。

今回の initial fix では次を行わない。

- `flutter_markdown` を置換する。
- table / list / link の native renderer を新規実装する。
- page 全体の native / legacy 判定を block-level renderer へ全面変更する。
- fallback source offsets を推測する。

安全な cache と state isolation 後も fallback ページだけが明確に重い場合、block-level rendering または upstream renderer 改善を別の設計タスクとして扱う。

---

## 10. Sliver / virtualization policy

`SingleChildScrollView + Column` による全 block build は長大ページで追加コストになり得るが、最初の performance patch では変更しない。

理由:

- selectable paragraph の lifecycle が変わる。
- offscreen disposal と selection handle の相互作用を追加検証する必要がある。
- scroll position、semantics、focus、selection toolbar の回帰リスクがある。
- 現在確認できる不要な再計算を先に止める方が小さく安全である。

Phase 1–5 完了後の profile でも長大単一ページの初回 layout が許容できない場合に限り、別文書で検討する。

その場合も次を必須とする。

- paragraph selection behavior を維持する。
- scroll jump を発生させない。
- visible hyphen overlay を維持する。
- offscreen paragraph の破棄で current selection を壊さない。
- line-per-widget implementation にしない。

---

## 11. Performance acceptance criteria

任意の端末固有 FPS 数値だけでなく、処理回数の不変条件を必須とする。

### 11.1 Planner

```text
planReaderMarkdown
- once per new page Markdown
- zero additional calls on scroll
- zero additional calls on selection changes
- zero additional calls on note changes
- zero additional calls on appearance changes
```

### 11.2 Emergency word breaking

```text
EmergencyWordBreaker.breakText
- Natural: zero
- Academic: once per paragraph text / mode activation
- zero additional calls on scroll
- zero additional calls on selection changes
- zero additional calls on note changes
- zero additional calls on font size / density / palette changes
- zero additional calls on width / orientation changes
```

### 11.3 Overlay layout

```text
HyphenOverlayLayoutEngine.compute
- once for a new effective layout key
- zero additional calls on steady scroll
- zero additional calls on selection-only changes
- zero additional calls on note-only changes
- recompute allowed when width, font metrics, scaler, line height, or display text changes
```

### 11.4 Reader subtree

- selection strip update だけで `BrrkReaderPage` を rebuild しない。
- note chip update だけで paragraph renderer を rebuild しない。
- same page の repeated parent UI updates で prepared paragraph text を再生成しない。
- scroll 中に Markdown parse、Emergency word breaking、UTF-8 encode、TextSpan traversal を追加実行しない。

### 11.5 Memory

- cache は page / paragraph widget lifecycle に従って解放される。
- document 数に比例して残り続ける global map を作らない。
- cache key に全文の重複コピーを不必要に保持しない。
- page change 後に旧 page の large mapping を保持し続けない。

---

## 12. Functional regression matrix

最低限、以下を実機と widget/unit tests で確認する。

| Mode | Source | Content | Required result |
|---|---|---|---|
| Natural | Paper | plain English | start align, no soft hyphen, selection works |
| Natural | Paper | Japanese | unchanged, selection works |
| Academic | Paper | long Latin words | justified, actual breaks show visible hyphen |
| Academic | Paper | protected tokens | URL/email/path/code unchanged |
| Natural | PDF | native prose | selection, Add Note, Look up work |
| Academic | PDF/native path | long Latin words | existing shared-reader behavior preserved |
| Natural | PDF | emphasis/link fallback | rendered plain-text selection works |
| Natural | PDF | Markdown table fallback | scroll and selection remain correct |
| Both | Paper/PDF | font sizes 12/17/24/32 | no period-like regression, correct layout |
| Both | Paper/PDF | all densities | no clipping or overlay drift |
| Both | Paper/PDF | portrait/landscape | line breaks and overlay recompute correctly |

Selection interaction:

- double tap
- long press
- selection handle drag forward
- selection handle drag backward
- collapsed selection
- selection clear
- Copy
- Add Note
- Look up

Canonical checks:

- copied word has no `U+00AD`.
- selected word has no decorative hyphen artifact.
- note text has no `U+00AD`.
- vocabulary term/context has no `U+00AD`.
- source offsets remain exact where currently guaranteed.
- fallback offsets remain `null` where exactness is not guaranteed.

---

## 13. Required tests

### 13.1 Planner cache tests

Add tests proving exact planner invalidation behavior.

Do not test only the final widget type. Count planner executions through a small test seam or equivalent deterministic mechanism.

### 13.2 Paragraph preparation cache tests

Use a counting `EmergencyWordBreaker` or counting `ReaderParagraphLayout` test seam.

Prove:

- one initial Academic preparation,
- no repeat on same-input rebuild,
- no repeat on appearance change,
- repeat on text or mode change only.

### 13.3 Overlay compute-count tests

Maintain and extend the existing counting engine tests.

Prove no recompute on:

- scroll,
- selection strip update,
- note update,
- same-width rebuild.

Prove recompute on:

- width change,
- font size change,
- density / line-height change,
- display text change.

### 13.4 Selection isolation tests

Use a build-counting wrapper or injected callback to verify action UI updates without reader rebuild.

Test Paper and PDF separately because note offset contracts differ。

### 13.5 Existing regression tests

At minimum, preserve all tests covering:

- EmergencyWordBreaker eligibility and protected ranges
- idempotence
- HyphenatedText mapping
- canonical selection
- AcademicSelectableText
- visible hyphen placement
- no baseline drift
- PDF fallback rendered-text callback
- PDF selected strip / Look up
- Paper exact offsets
- Add Note
- vocabulary candidate recovery

---

## 14. Validation commands

最低限:

```bash
flutter pub get
flutter analyze
flutter test test/brrk_reader_page_test.dart
flutter test test/pdf_viewer_screen_test.dart
flutter test test/reader_paragraph_layout_test.dart
flutter test test/emergency_word_breaker_test.dart
flutter test test/academic_selectable_text_test.dart
flutter test test/visible_hyphen_painter_test.dart
flutter test test/renderer_integration_test.dart
flutter test
```

Rust を変更していなくても repository standard validation として可能な範囲で実行する。

```bash
cd rust
cargo fmt --check
cargo clippy -- -D warnings
cargo test -- --test-threads=1
cd ..
git diff --check
```

実機:

```bash
flutter run --profile -d <device-id>
flutter build apk --debug
flutter build apk --release
```

Profile mode の Flutter DevTools で、Phase 0 と同じ操作を実行し、before / after を比較する。

---

## 15. Implementation order and commit boundaries

推奨 commit 分割:

```text
1. test(reader): add performance regression counters
2. perf(reader): cache markdown render plan
3. perf(reader): cache paragraph text preparation
4. perf(reader): isolate selection action state
5. perf(reader): isolate note-only updates
6. perf(settings): defer font-size persistence
7. test(reader): add device-profile acceptance documentation
```

各 commit で analyzer と focused tests を通す。複数 phase を一度に混ぜて、どの変更で selection / hyphenation が壊れたか分からない状態にしない。

---

## 16. Completion criteria

以下をすべて満たした場合のみ完了とする。

- same Markdown の parent rebuild で `planReaderMarkdown()` が再実行されない。
- same Academic paragraph の rebuild で `EmergencyWordBreaker.breakText()` が再実行されない。
- selection handle movement で reader subtree が rebuild されない。
- note-only update で OCR paragraph preparation が再実行されない。
- steady scroll 中に Markdown parse、word breaking、overlay layout recompute が発生しない。
- font slider drag 中の SharedPreferences write が抑制される。
- Natural mode の表示と selection が変わらない。
- Academic mode の justify、Emergency word breaking、visible hyphen が変わらない。
- eligible insertion boundary を間引いていない。
- protected token rules が変わらない。
- visible hyphen の長さ・位置・baseline behavior が回帰していない。
- Copy / Add Note / Look up / semantics に `U+00AD` または装飾ハイフンが漏れない。
- Paper exact source offsets と UTF-8 note offsets が維持される。
- PDF fallback rendered-text selection contract が維持される。
- Rust / FRB / OCR / storage format に不要な変更がない。
- global unbounded cache がない。
- focused tests、full Flutter tests、analyzer が成功する。
- debug / profile / release の実機確認を行う。
- before / after profile で不要な planner / breaker / overlay calls が消えている。

---

## 17. Implementation report format

coding agent は完了時に次を報告する。

1. baseline の再現条件と対象端末
2. before / after の planner、breaker、overlay compute 回数
3. 変更したファイル
4. cache key と invalidation 条件
5. selection state isolation の構造
6. note state isolation の構造
7. font persistence の変更
8. hyphenation / visible-hyphen invariants を維持した根拠
9. 追加・更新した tests
10. 実行した validation commands と結果
11. 実行できなかった検証と理由
12. 今回 deferred にした項目

---

## 18. Deferred follow-ups

以下は initial fix 完了後も profile 上で必要性が確認された場合だけ別タスクにする。

- long page の Sliver / virtualization
- block-level native / fallback Markdown rendering
- fallback renderer の upstream performance patch
- layout-only style key による overlay cache key の細分化
- UTF-16 → UTF-8 offset prefix table
- large document precomputation / background preparation

これらを initial fix に混ぜない。まず既存機能を完全に保持したまま、同じ入力への重複処理を除去する。
