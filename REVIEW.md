# REVIEW.md — 可変フォントサイズ時のハイフン視認性修正

## 1. 目的

Academic レイアウトで行末に表示される装飾ハイフンが、フォントサイズによって短い点のように見え、ピリオドと誤認される問題を修正する。

修正は既存の設計を維持した最小変更とし、コードベースの複雑化、描画パフォーマンスの低下、Flutter と Rust の責務混在を発生させないこと。

## 2. 確認済みの原因

対象コード:

- `lib/src/app/reader/hyphenation/hyphen_overlay_layout.dart`
- `test/visible_hyphen_painter_test.dart`

現在の装飾ハイフンは文字グリフではなく、`HyphenOverlayLayoutEngine` が計算した水平線を `VisibleHyphenPainter` が `Canvas.drawLine` で描画している。

現在の寸法ポリシー:

```dart
final strokeLength =
    (scaledFontSize * 0.34).clamp(5.0, 9.0).toDouble();
final strokeWidth =
    (scaledFontSize * 0.065).clamp(1.0, 1.5).toDouble();
```

長さと太さの上限が低いため、大きいフォントでは本文だけが拡大し、装飾ハイフンが相対的に短く細くなる。小さいフォントでは 5px × 1px 付近に固定され、端末のラスタライズによって点に近く見える場合がある。

キャッシュキーには `TextStyle` と `TextScaler` が含まれているため、古い寸法が再利用されるキャッシュ不整合が主因ではない。

## 3. 必須の修正

### 3.1 寸法ポリシーだけを変更する

`hyphen_overlay_layout.dart` で、既存の比例係数を維持し、クランプ範囲を次の値へ変更する。

```dart
const double _minHyphenLength = 5.5;
const double _maxHyphenLength = 12.0;
const double _minHyphenStrokeWidth = 1.1;
const double _maxHyphenStrokeWidth = 2.0;
```

計算:

```dart
final strokeLength = (scaledFontSize * 0.34)
    .clamp(_minHyphenLength, _maxHyphenLength)
    .toDouble();

final strokeWidth = (scaledFontSize * 0.065)
    .clamp(_minHyphenStrokeWidth, _maxHyphenStrokeWidth)
    .toDouble();
```

期待値の目安:

| Font size | Length | Stroke width |
| ---: | ---: | ---: |
| 12sp | 5.5px | 1.1px |
| 17sp | 5.78px | 1.105px |
| 24sp | 8.16px | 1.56px |
| 32sp | 10.88px | 2.0px |

17sp 前後の既存表示をほぼ維持しながら、対応範囲の両端で視認性を改善すること。

### 3.2 既存テストの不足を修正する

`test/visible_hyphen_painter_test.dart` の既存テストは、名称が stroke length policy であるにもかかわらず `strokeWidth` だけを取得している。また、長さについては `greaterThan(0)` しか検証していない。

次をテストすること。

1. 12sp、17sp、24sp、32sp で装飾線が生成される。
2. 各サイズで線が水平であり、長さと太さが有限かつ正である。
3. 12sp の長さが 5.5px 以上、太さが 1.1px 以上である。
4. 32sp の長さが 10.5px 以上、太さが 1.9px 以上である。
5. 12sp → 17sp → 24sp → 32sp の順で、長さと太さが非減少である。
6. 24sp から 32sp で長さが実際に増加し、旧上限 9px に固定されない。
7. 17sp の寸法が既存値から不必要に変化しない。

浮動小数点の比較には、完全一致ではなく `closeTo` または適切な範囲検証を使うこと。

テスト用の小さな helper を追加してもよいが、production code に新しい geometry abstraction を導入しないこと。

## 4. 変更してはいけないもの

今回の修正では、以下を変更しないこと。

- `EmergencyWordBreaker` の単語判定または `U+00AD` 挿入規則
- `HyphenatedText` の display-to-source mapping
- 選択、コピー、Add Note、Vocabulary の canonical offset 処理
- `AcademicSelectableText` の widget 構造
- `HyphenOverlayLayoutEngine` と `VisibleHyphenPainter` の二段階構造
- レイアウトキャッシュおよびキャッシュキー
- hanging hyphen gutter の幅
- `Canvas.drawLine` による stroke-only painter
- PDF と Paper の共有 reader path
- Rust、flutter_rust_bridge、OCR、永続化、キャッシュ、validation

`U+2010` などの文字グリフを別の `TextPainter` で描画する方式へ戻さないこと。Painter 内でテキストレイアウトを再実行しないこと。

Device Pixel Ratio を新しい入力やキャッシュキーとして導入しないこと。今回の寸法修正後も特定端末でのみ滲みが残ることを確認できた場合に、別タスクとして扱う。

## 5. Flutter と Rust の責務

### Flutter

Flutter が所有する:

- フォントサイズと `TextScaler`
- `TextPainter` による行レイアウト
- 改行された soft hyphen の検出
- 装飾ハイフンの座標、長さ、太さ
- 表示用 `U+00AD`
- display selection から canonical selection への変換

### Rust

Rust が所有する:

- OCR と canonical text
- PDF／紙書籍データ
- 永続化
- ノート、語彙、キャッシュ、validation
- canonical offset または UTF-8 byte offset

今回の問題は Flutter のフォントメトリクスと描画寸法に限定される。Rust 側へフォントサイズ、行幅、装飾ハイフン情報を渡してはならない。

## 6. パフォーマンス要件

修正後も次の条件を維持すること。

- `VisibleHyphenPainter.paint()` は事前計算された線を描画するだけである。
- `paint()` 内で `TextPainter`、soft-hyphen scan、line metrics 計算を行わない。
- レイアウト入力が変わらない rebuild／scroll で `HyphenOverlayLayoutEngine.compute()` を再実行しない。
- soft hyphen 1件あたりの描画コストを増やさない。
- 新しい依存パッケージを追加しない。

定数と既存の算術式を変更するだけなので、runtime complexity と allocation profile は現状を維持できるはずである。

## 7. 実装手順

1. 関連ファイルと既存テストを読み、上記の原因が現在のコードにも当てはまることを確認する。
2. `hyphen_overlay_layout.dart` の寸法ポリシーを最小変更する。
3. `visible_hyphen_painter_test.dart` の誤解を招く既存テストを修正し、長さと太さの両方を検証する。
4. 関連テストを実行する。
5. Flutter analyzer を実行する。
6. diff を確認し、スコープ外変更がないことを確認する。

## 8. 検証コマンド

最低限、以下を実行すること。

```bash
flutter test test/visible_hyphen_painter_test.dart
flutter test test/academic_selectable_text_test.dart
flutter test test/reader_paragraph_layout_test.dart
flutter analyze
```

可能であれば、全テストも実行する。

```bash
flutter test
```

## 9. 完了条件

以下をすべて満たした場合のみ完了とする。

- 12–32sp の範囲でハイフン寸法が本文サイズに追従する。
- 大きいフォントで旧上限 9px × 1.5px に固定されない。
- 小さいフォントで最低 5.5px × 1.1px を確保する。
- 既存の行折り返し位置、選択、コピー、canonical mapping を変更しない。
- Painter、layout engine、cache の責務分離を維持する。
- Rust／FRBコードに変更がない。
- 新しい依存関係がない。
- 関連テストと analyzer が成功する。

## 10. 実装後の報告形式

coding agent は完了時に次を簡潔に報告すること。

1. 変更したファイル
2. 寸法ポリシーの変更内容
3. 追加または修正した回帰テスト
4. 実行した検証コマンドと結果
5. 実行できなかった検証がある場合は、その理由
6. スコープ外の問題を発見した場合は、実装せず別項目として記載
