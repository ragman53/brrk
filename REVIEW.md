# REVIEW.md — PDF fallback renderer の選択・Vocabulary 回帰修正

## 1. 目的

PDF View で単語を選択しても選択アクションの `Look up` が利用できず、Vocabulary 系機能が動作しない問題を修正する。

Paper View の native prose 経路は正常に動作しているため、Paper と PDF の機能を別実装に分岐させず、共有 reader の fallback Markdown 選択経路だけを最小修正すること。

修正では次を必須とする。

- コードベースを不必要に複雑化しない。
- 選択中やスクロール中のパフォーマンスを低下させない。
- Flutter と Rust の責務境界を維持する。
- 表示文字列と selection offset の対応を推測しない。
- Paper View、native prose、hyphenation、Add Note を回帰させない。

## 2. 確認済みの症状

- Paper View では選択後に `Look up` が利用できる。
- PDF View では一部のページで選択後に `Look up` が表示されない、または無効になる。
- PDF OCR Markdown は強調、リンク、リスト、引用、テーブルなどを含む場合があり、そのページは `LegacyMarkdownPlan` へ切り替わる。
- `LegacyMarkdownPlan` は `flutter_markdown` の `MarkdownBody(selectable: true)` を使用する。
- native prose 経路の `BrrkReaderParagraph` と `AcademicSelectableText` は canonical selection を正常に通知している。

デバッグ時は該当ページで次のような診断ログが出るか確認すること。

```text
BrrkReaderPage strategy=legacyMarkdown:<reason>
```

Paper View または単純なPDF本文では次になる場合がある。

```text
BrrkReaderPage strategy=nativeProse
```

## 3. 確認済みの原因

### 3.1 Brrk の fallback callback

対象:

```text
lib/src/app/reader/brrk_reader_page.dart
```

`_LegacyMarkdownBody` は `MarkdownBody.onSelectionChanged` の `text` を selection context として使用している。

```dart
onSelectionChanged: (text, selection, cause) {
  final contextText = text ?? '';
  // ...
}
```

`text` が `null` の場合、空文字列へ変換される。その後 selection offset が長さ0へ clamp され、`ReaderSelection` が発行されない。

PDF画面の `_handleReaderSelection` がイベントを受け取れないため、次の状態が設定されない。

- `_selectedText`
- `_selectedContext`
- `_lookupText`
- `_lookupStart`
- `_lookupEnd`

その結果、選択ストリップが表示されないか、`Look up` が無効になる。

### 3.2 `flutter_markdown 0.7.7+1` の rich text callback

現在の依存バージョン:

```text
flutter_markdown 0.7.7+1
```

`flutter_markdown` は強調やリンクなどを含むブロックを、子spanを持つ親 `TextSpan` として構築する場合がある。

```dart
TextSpan(children: spans)
```

この親span自身の `text` は `null` になり得る。しかし selectable rich text の callback では、表示ブロック全体を返す `toPlainText()` ではなく、親spanの `text` を渡している。

```dart
onSelectionChanged!(text.text, selection, cause)
```

このため、callback contract が意図する「選択可能なブロック全体の表示テキスト」ではなく `null` がBrrkへ渡る。

### 3.3 直近のハイフン修正との関係

直近のハイフン視認性修正は次の2ファイルだけを変更している。

```text
lib/src/app/reader/hyphenation/hyphen_overlay_layout.dart
test/visible_hyphen_painter_test.dart
```

選択処理、PDF画面、Vocabulary処理は変更していない。今回の問題をハイフン寸法の変更で解決しようとしてはならない。

## 4. 修正方針

### 4.1 原則

`flutter_markdown` が callback へ返す selection context を、表示されているプレーンテキスト全体に修正する。

修正対象は `flutter_markdown` の selectable rich text callback とし、Brrk側でMarkdown sourceから表示テキストやoffsetを推測しないこと。

### 4.2 必須のcallback修正

`flutter_markdown` の `_buildRichText` 相当箇所で、親spanの `text` ではなく、span tree全体のプレーンテキストを渡す。

期待する形:

```dart
Widget _buildRichText(
  TextSpan text, {
  TextAlign? textAlign,
  String? key,
}) {
  final plainText = text.toPlainText(
    includeSemanticsLabels: false,
  );

  final resolvedKey = key == null ? UniqueKey() : Key(key);

  if (selectable) {
    return SelectableText.rich(
      text,
      textScaler: styleSheet.textScaler,
      textAlign: textAlign ?? TextAlign.start,
      onSelectionChanged: onSelectionChanged == null
          ? null
          : (selection, cause) {
              onSelectionChanged!(plainText, selection, cause);
            },
      onTap: onTapText,
      key: resolvedKey,
    );
  }

  return Text.rich(
    text,
    textScaler: styleSheet.textScaler,
    textAlign: textAlign ?? TextAlign.start,
    key: resolvedKey,
  );
}
```

重要な契約:

```dart
callbackText == text.toPlainText(includeSemanticsLabels: false)
```

`plainText` はwidget構築時に一度だけ生成し、選択変更callbackのたびに `toPlainText()` を実行しないこと。

### 4.3 依存関係の管理

`.pub-cache` 内のファイルを直接編集してはならない。再取得時に消失し、再現可能なbuildにならない。

推奨する依存管理:

1. `flutter_markdown` の現在使用中の版を基点に最小forkを作る。
2. callback修正とそのpackage-level regression testだけを追加する。
3. Brrkの `pubspec.yaml` ではforkのimmutable commit SHAへ固定する。
4. ブランチ名や可変tagだけへ依存しない。
5. fork理由と上流へ戻す条件を `pubspec.yaml` 付近のコメントまたは短い依存メモに記載する。

例:

```yaml
flutter_markdown:
  git:
    url: <fork repository URL>
    ref: <immutable commit SHA>
```

coding agentが外部forkを作成できない環境の場合、勝手に `.pub-cache` を編集したり未固定branchへ依存したりせず、その制約を報告すること。Brrkリポジトリ内へのpackage丸ごとのvendorは、外部forkが不可能な場合に限り検討し、実施前に差分規模と更新方法を明示すること。

### 4.4 Brrk側の防御

Brrk側では `text == null` をMarkdown sourceへ置き換えて処理を続行してはならない。

必要であれば `_LegacyMarkdownBody` のコメント、assert、テストを改善してよい。ただし、正しいcontextがpackageから渡ることを前提にする。

`null` または空contextを受け取った場合は、誤ったoffsetでVocabularyやAdd Noteを実行するより、現在と同様にイベントを発行しないfail-closed動作を維持する。

## 5. 禁止する修正

次を行ってはならない。

### 5.1 Markdown sourceをselection contextとして代用しない

禁止例:

```dart
final contextText = text ?? markdown;
```

表示後のselection offsetはプレーンテキスト座標である。一方、Markdown sourceには `*`、`_`、`[]()`、URL、list markerなどが含まれるため、座標が一致しない。

例:

```markdown
This is *important*.
```

表示テキスト:

```text
This is important.
```

sourceと表示テキストのoffsetを混在させると、別の文字列をlookupしたり、不正なoffsetをRustへ渡したりする。

### 5.2 PDF専用のVocabulary実装を追加しない

- PaperとPDFで別の候補抽出ロジックを作らない。
- `vocabularyCandidateFromSelection` を複製しない。
- PDFだけにGestureDetectorや独自単語推測を重ねない。
- `PdfViewerScreen` でMarkdownを再parseしてselected wordを推測しない。

### 5.3 native plannerを無制限に拡張しない

今回の修正のために、強調、リンク、リスト、テーブル、引用などの完全なnative rendererを実装しない。これは別の設計タスクである。

### 5.4 RustへUI選択復元を移さない

- RustでMarkdown表示文字列を再構築しない。
- RustへFlutterの `TextSelection` をそのまま渡さない。
- FRB APIを変更しない。
- OCR、storage、models、Vocabulary persistenceを変更しない。

### 5.5 hyphenation経路を変更しない

- `EmergencyWordBreaker`
- `HyphenatedText`
- `AcademicSelectableText`
- `HyphenOverlayLayoutEngine`
- `VisibleHyphenPainter`

今回のfallback問題と無関係なため変更しない。

## 6. FlutterとRustの責務

### Flutterが所有するもの

- Markdownから実際に表示されるテキストへの変換
- `SelectableText` と `TextSpan` tree
- `TextSelection` のUTF-16 code-unit offset
- selection contextとselection rangeの整合性
- `ReaderSelection` の生成
- Vocabulary候補のUI側正規化
- 選択ストリップ、`Look up`、`Add Note` の表示状態

### Rustが所有するもの

- OCRによるcanonical sourceの生成
- PDF／Paperデータ
- Vocabulary lookup requestと結果
- 永続化、キャッシュ、validation
- source typeとdocument/page identity
- 必要な箇所でのUTF-8 byte offset

今回の不具合はFlutterのrendered-text selection contextで発生している。Rust／FRBを変更しないこと。

## 7. パフォーマンス要件

修正後も次を維持すること。

- `TextSpan.toPlainText()` はwidget構築時に一度だけ実行する。
- 選択ハンドルの移動ごとにspan tree全体を走査しない。
- `PdfViewerScreen._handleReaderSelection` の計算量を増やさない。
- スクロール中に追加のMarkdown parseやtext layoutを実行しない。
- native prose、Academic overlay、layout cacheへ影響を与えない。
- 新しい状態管理層やstreamを追加しない。
- selection 1回ごとのRust呼び出しを追加しない。Rust lookupは利用者が `Look up` を押した後だけ開始する。

## 8. 必須テスト

### 8.1 patched `flutter_markdown` package-level test

rich spanを生成するMarkdownまたは等価な `TextSpan(children: ...)` を使用し、実際の `SelectableText.rich` callbackがプレーンテキスト全体を返すことを検証する。

最低限のケース:

```markdown
This is *philosophical* text with a [reference](https://example.com).
```

検証:

- callback text が `null` ではない。
- callback text が表示テキスト全体と一致する。
- callback textにMarkdown markerやlink destinationが含まれない。
- `selection.textInside(callbackText)` が選択した単語と一致する。
- plain paragraphでも既存callback contractを維持する。

### 8.2 `BrrkReaderPage` fallback integration test

対象:

```text
test/brrk_reader_page_test.dart
```

既存テストのように `MarkdownBody.onSelectionChanged` を正常な文字列付きで直接呼ぶだけでは不十分である。その方法はpackageの実際の `null` callbackを迂回する。

実際に `MarkdownBody` 配下に生成された `SelectableText` または `SelectableText.rich` の `onSelectionChanged` を呼び、共有readerまでイベントが到達することを検証する。

検証:

- fallback strategyが選択される。
- `ReaderSelection` が `null` ではない。
- `canonicalContext` が表示プレーンテキストである。
- `canonicalContext` にMarkdown marker、link URL、`U+00AD` が漏れない。
- selection substringが選択語と一致する。
- `sourceStart` と `sourceEnd` は fallback contractどおり `null` である。
- `SelectionChangedCause` が失われない。

### 8.3 `PdfViewerScreen` regression test

対象:

```text
test/pdf_viewer_screen_test.dart
```

fallbackが必要なPDF Markdownを読み込む。

例:

```markdown
<!-- page: 1 -->
This is *philosophical* text with a [reference](https://example.com).
```

実際の選択callbackを発火させ、次を検証する。

- `BrrkReaderPage` と `MarkdownBody` が使用される。
- 選択後にselected stripが表示される。
- selected stripのタイトルが選択語を含む。
- `Look up` ボタンが存在する。
- `Look up` ボタンの `onPressed` が `null` ではない。
- `Add Note` が引き続き利用できる。
- 選択解除時にstripとlookup stateがクリアされる。

外部APIやRust storageを実行しないよう、lookupボタンを実際に押す必要はない。ボタンが有効であるところまでをwidget testで検証する。

### 8.4 Paper/native regression

既存のPaper/native選択テストを維持し、次を確認する。

- Paper Viewの `Look up` が引き続き利用できる。
- native prose selectionのexact source offsetが維持される。
- UTF-8 byte offset変換が維持される。
- Academic soft-hyphen selection mappingが維持される。

## 9. 実装手順

1. 現在の `pubspec.lock` と `flutter_markdown` sourceを確認し、原因を再現する最小テストを先に作る。
2. package-level testが旧実装で失敗することを確認する。
3. `text.text` を `text.toPlainText(includeSemanticsLabels: false)` ベースへ最小修正する。
4. forkをimmutable commit SHAでBrrkへ固定する。
5. `BrrkReaderPage` のfallback integration testを追加する。
6. `PdfViewerScreen` の実際の選択から有効な `Look up` までをテストする。
7. Paper/native/hyphenationの関連テストを実行する。
8. analyzerと全テストを実行する。
9. diffを確認し、Rust、FRB、hyphenation、storageに変更がないことを確認する。

## 10. 検証コマンド

最低限、Brrkリポジトリで以下を実行する。

```bash
flutter pub get
flutter test test/brrk_reader_page_test.dart
flutter test test/pdf_viewer_screen_test.dart
flutter test test/reader_paragraph_layout_test.dart
flutter test test/academic_selectable_text_test.dart
flutter test test/visible_hyphen_painter_test.dart
flutter analyze
```

forkしたpackage側でも、そのpackageのテストを実行する。

```bash
flutter test
```

Brrk全体でも可能な限り実行する。

```bash
flutter test
```

依存解決後、`pubspec.lock` が意図したimmutable fork commitを参照していることを確認する。

## 11. 完了条件

以下をすべて満たした場合のみ完了とする。

- rich Markdownを含むPDFページで単語選択後にselected stripが表示される。
- `Look up` ボタンが有効になる。
- Vocabulary候補が選択した表示単語と一致する。
- callback contextが `null` ではなく、表示プレーンテキスト全体である。
- Markdown sourceと表示offsetを混在させていない。
- fallback `sourceStart`／`sourceEnd` は推測せず `null`を維持する。
- Add Noteが回帰していない。
- Paper Viewとnative proseが回帰していない。
- Academic hyphenationとcanonical mappingが回帰していない。
- 選択callbackごとの追加span traversalがない。
- Rust／FRB／OCR／storage codeに変更がない。
- `.pub-cache` の直接編集がない。
- 依存先がimmutable commit SHAへ固定されている。
- package-level regression test、Brrk integration test、analyzerが成功する。

## 12. 実装後の報告形式

coding agentは完了時に次を簡潔に報告すること。

1. 原因の再現方法
2. 変更したリポジトリとファイル
3. forkまたは依存固定のcommit SHA
4. callback contractの変更内容
5. 追加・修正した回帰テスト
6. 実行した検証コマンドと結果
7. Rust／FRB／hyphenationを変更していないこと
8. 実行できなかった検証がある場合は、その理由
9. 上流packageへ戻すための条件またはfollow-up
