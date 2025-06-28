### **【開発依頼プロンプト】AI連携テストカバレッジ改善ツール "Test Sentinel" の開発**

#### 1. プロジェクトの目的と概要

本プロジェクトの目的は、Railsアプリケーションにおけるテストカバレッジの「穴」をインテリジェントに発見し、**AIエージェント（Claude Sonnet 3.5）と連携してテストコードの生成までを自動化する、自己完結型のCLIツール "Test Sentinel" を開発する**ことです。

このツールは、単なる分析レポートの出力に留まりません。分析結果に基づき、最も効果的なテストコード生成のためのプロンプトを自動生成し、AIエージェントを起動して、開発者の負担を抜本的に削減することを最終ゴールとします。

#### 2. コア・コンセプト

* **AI非使用の精密分析:** テストすべき箇所の特定（分析フェーズ）は、再現性と正確性を担保するため、AIを使用せず、カバレッジ、コード複雑度、更新頻度などの客観的指標に基づいたアルゴリズムで実行します。
* **AIへの高品質なインプット提供:** 分析フェーズで得られた構造化データを基に、AIエージェントの能力を最大限に引き出す、高品質でコンテキスト豊富なプロンプトを生成します。

#### 3. 機能要件詳細

メソッド単位で「テスト拡充の優先度（危険度スコア）」を算出し、テスト対象のリストを作成します。

**3.1. 入力データ**

以下の3つの情報源からデータを収集します。

1.  **テストカバレッジ:** `simplecov`が生成する`coverage/.resultset.json`を読み込みます。
2.  **コード複雑度:** `rubocop --format json`を実行し、各メソッドの循環的複雑度 (`Metrics/CyclomaticComplexity`) の値を取得します。
3.  **更新頻度:** `git log --name-only` コマンドを利用し、過去90日間など、指定期間内の各ファイルのコミット回数を集計します。

**3.2. 優先度スコア計算ロジック**

各メソッドの優先度スコアを、以下の式に基づいて算出します。

`Score = (W_cov * CoverageFactor) + (W_comp * ComplexityFactor) + (W_git * GitFactor) + (W_dir * DirectoryFactor)`

* **各要素:**
    * `CoverageFactor`: `(1.0 - カバレッジ率)` で算出。カバレッジが低いほど高くなる。
    * `ComplexityFactor`: `rubocop`から取得した循環的複雑度の値。
    * `GitFactor`: ファイルのコミット回数。
    * `DirectoryFactor`: ファイルのパスに応じて設定する係数（例: `app/models`は1.5, `app/controllers`は1.0）。
* **重み付け（パラメータ化）:**
    * `W_cov`, `W_comp`, `W_git`, `W_dir` は、後述する設定ファイル (`sentinel.yml`) でユーザーが自由に調整できる**重みパラメータ**とします。

**3.3. 推奨テストシナリオの生成**

* 分析対象メソッドのソースコードを静的解析します。
* メソッド内の `if`, `unless`, `case` などの条件分岐文を特定します。
* 例えば `if user.admin? && !user.locked?` という条件文があれば、「`user.admin?`がtrueかつ`user.locked?`がfalseの場合」「それ以外の場合」といった、**具体的で人間が理解しやすいテストシナリオの文字列**を生成します。

**3.4. 分析結果の出力（中間データ）**

* 分析結果として、優先度スコアの高い順にソートされたメソッドのリストを、内部的にJSON形式で保持します。

<!-- end list -->

```json
[
  {
    "file_path": "app/services/payment_service.rb",
    "class_name": "PaymentService",
    "method_name": "calculate_fee",
    "line_number": 25,
    "score": 95.4,
    "details": {
      "coverage": 0.3,
      "complexity": 12,
      "git_commits": 15
    },
    "suggested_scenarios": [
      "userがpremiumプランの場合",
      "userがfreeプランで、月の決済回数が上限未満の場合",
      "userがfreeプランで、月の決済回数が上限以上の場合 (例外発生)"
    ]
  }
]
```

#### 4. CLI（コマンドラインインターフェース）仕様

* **コマンド名:** `test-sentinel`
* **実行コマンド:** `bundle exec test-sentinel generate`
* **オプション:**
    * `--top-n N` : テストを自動生成する対象を、優先度上位N件に絞る（デフォルト: 3）。
    * `--config FILE_PATH`: 設定ファイルのパスを指定する（デフォルト: `./sentinel.yml`）。

#### 5. 設定ファイル仕様

ツールの挙動を制御するための設定ファイルをYAML形式で用意します。

**`sentinel.yml` (例)**

```yaml
# 優先度スコアの重み付け
score_weights:
  coverage: 1.5
  complexity: 1.0
  git_history: 0.8
  directory: 1.2

# ディレクトリごとの重要度
directory_weights:
  - path: "app/models/"
    weight: 1.5
  - path: "app/services/"
    weight: 1.5
  - path: "app/jobs/"
    weight: 1.2

# 分析から除外するファイルのパターン
exclude:
  - "app/channels/**/*"
  - "app/helpers/**/*"
```

#### 6. 開発言語・技術スタック

  * **開発言語:** Ruby
  * **依存:** `simplecov`, `rubocop`, `git`コマンドが実行環境に存在することを前提とします。
