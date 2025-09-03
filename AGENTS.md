# AGENTS.md — アンケート（投票）アプリ

## 0) ゴールと前提

* **目的**: 複数の AI エージェントに同一仕様の Web アプリを実装させ、共通指標で成果物を比較・評価する。
* **テーマ**: アンケート（投票）アプリ。ログイン無し・ライトな重複投票対策・公開結果の表示。
* **人間の役割**: `rails new` まで。以降の設計・実装・テスト・ドキュメント・コミットは AI Agent が担当。
* **技術制約**

  * Rails 8 / Ruby（プロジェクトの既定）
  * DB: **SQLite**
  * CSS: **Tailwind（tailwindcss-rails）**
  * JS: **importmap**（Node ビルドなし）
  * **Redis は使用しない**（Action Cable / Turbo Streams 不使用。Turbo Drive/Frames は可）
  * 認証無し（**Cookie + サーバー側ハッシュ**で簡易重複投票制御）
  * i18n: `ja` を既定
  * タイムゾーン: `Asia/Tokyo`
* **評価観点**（両モデル比較用）

  1. 設計の明確さ（モデル、責務分割、命名）
  2. 実装品質（Rails慣習、バリデーション、N+1対策、テスト）
  3. UI/UX（Tailwind の活用、アクセシビリティ、フォーム体験）
  4. 安定性（エラー処理、境界条件、重複投票抑止）
  5. ドキュメント/コミットログの可読性（プロンプト入出力・トークン記録）

## 0.x) ドキュメント/バージョン方針（Active Record）

- Active Record の API/使い方は **公式 Rails Guides（v8系）** を一次情報として参照すること。
  - 例: Active Record Basics / Query Interface / Associations / Migrations
- **Rails 8 固有の変更点に注意**（8.0 Release Notes などを都度確認）。
  - 例: `enum` の旧来のキーワード引数形の削除、`SQLite3Adapter` の `retries` 非推奨（`timeout`へ）、新規DBでの `db:migrate` は先に schema をロード など。
- ブログや旧記事の記法が出てきた場合は、**現行ガイドに合わせて修正**すること。
- 参考: Rails Guides（該当バージョン）, Release Notes（8.x）, Upgrading Guide。

## 1) 機能要件（MVP）

* **Poll（アンケート）** の作成・閲覧・投票・結果表示

  * 項目（Choice）を複数持つ単一選択投票（Phase 4 で複数選択拡張）
  * 投票後は結果（合計・比率バー）を表示
  * **重複投票の簡易抑止**: サイン済み Cookie + `voter_hash`（`ip + user_agent + secret_salt` を SHA256）で **Poll 単位のユニーク制約**
    ※PII は保持しない。`voter_hash` は不可逆ハッシュ。
  * Poll の公開状態：`draft/open/closed`。`open` のみ投票可能。`ends_at` 過ぎたら自動 close（アプリ層判定）
* **管理（最小限）**

  * 新規 Poll 作成（タイトル、説明、締切、選択肢）
  * Poll 公開/終了切替（UI ボタン）
* **UI**

  * Tailwind のモダンカードレイアウト
  * 投票画面：ラジオボタン + 送信
  * 結果画面：割合バー（CSS のみ）
  * フラッシュメッセージ、エラー表示
* **非機能**

  * 依存追加は最小限（**RSpec 等を入れず、既定の Minitest**を使用）
  * Turbo Streams 不使用（**Redis 不要**）
  * 1 コミットあたり **\~50–300 LOC 目安**、小さく進める

## 2) ドメイン設計（MVP）

### 2.1 モデル

* `Poll`

  * `title:string`, `description:text`, `slug:string:index:unique`
  * `status:integer`（enum: `draft:0, open:1, closed:2`）
  * `ends_at:datetime`（任意）
  * 関連: `has_many :choices, dependent: :destroy`, `has_many :votes, dependent: :destroy`
* `Choice`

  * `poll:references`
  * `label:string`, `votes_count:integer, default:0, null:false`（カウンタキャッシュ）
  * 関連: `belongs_to :poll, counter_cache: false`, `has_many :votes`
* `Vote`

  * `poll:references`, `choice:references`
  * `voter_hash:string`（null可・空可、Cookie 取れない環境対策）
  * **ユニークインデックス**: `index_votes_on_poll_id_and_voter_hash(unique: true, where: voter_hash IS NOT NULL)`
  * バリデーション：`poll_id` と `choice_id` の整合、`poll.open?` 時のみ作成

### 2.2 ユースケース

* 投票フロー

  1. `/polls/:slug` にアクセス → `open?` なら投票フォーム表示
  2. POST `/polls/:slug/votes` → Cookie 設定 & `voter_hash` 生成 → 既投票チェック → 保存 → 結果へ
  3. 結果は割合バー・総投票数表示。`closed`/締切超過はフォーム非表示。

## 3) UI / デザイン方針（Tailwind）

* **レイアウト**: コンテナ幅 `max-w-3xl`, 余白 `mx-auto px-4 sm:px-6 md:px-8`, 余白広め、余白→階層で情報整理
* **コンポーネント**: Card（shadow-sm, rounded-2xl, border）, Button（solid/outline）, Form（fieldset/legend/label/input/error）
* **配色**: デフォルト + `slate`/`indigo` ベース、成功/警告/エラーに `green/amber/rose`
* **アクセシビリティ**: ラベル関連付け、フォーカスリング、コントラスト、aria-live のフラッシュ
* **結果バー**: 各 Choice ごとに割合%を幅に反映（Tailwind の width を style 属性で動的適用）

## 4) 実装フェーズ（小さなコミットで）

> 各フェーズの中でも**1コミット＝1目的**（マイグレーション、コントローラ、ビュー、スタイル、テスト…を細分化）。

### Phase 0 — 初期状態の確認（人間完了後、Agent が最小コミット）

* 受け取る前提: 人間が実行済み

  ```bash
  rails new . --database=sqlite3 --minimal --javascript=importmap --css=tailwind
  bin/rails db:create
  bin/dev # or rails s
  ```
* Agent: README に**実行手順**追記、`application.html.erb` にヘッダー/コンテナ追加、i18n/タイムゾーン設定
* ✅: ルートに「Pollsへ」リンク、Tailwind の適用確認

### Phase 1 — ドメイン/マイグレーション

* モデル作成、enum、バリデーション、インデックス、`voter_hash` 一意制約
* Seed にダミー Poll + Choice 作成
* ✅: `rails db:seed` 後、コンソールで関連が機能

### Phase 2 — Poll CRUD（管理最小）

* `PollsController`（index/show/new/create/edit/update/close）
* `slug` 自動生成（parameterize + ショート化）
* ステータス `draft/open/closed` のトグル UI
* ✅: Poll 作成→open 化→show 表示

### Phase 3 — Choice 管理（Nested）

* Poll 編集画面で Choice の追加/削除（fields\_for + accepts\_nested\_attributes\_for）
* ✅: Choice を 2つ以上登録できる

### Phase 4 — 投票フロー（単一選択）

* `VotesController#create`
* Cookie 読み書き（署名付き）、`voter_hash` 生成（`ip + user_agent + Rails.application.credentials.secret_key_base`）
* 重複投票エラー → フラッシュ表示
* 成功で結果画面へ
* ✅: 同一環境から二重投票できない

### Phase 5 — 結果表示/締切

* 結果コンポーネント（割合バー、合計票数）
* `ends_at` 過ぎたら `closed` と同等の扱い（フォーム非表示）
* ✅: 締切超過で投票不可

### Phase 6 — UI 仕上げ/アクセシビリティ

* フォームエラー、フォーカスリング、aria ライブ、ボタン状態
* ✅: Lighthouse（手動）で致命的課題なし

### Phase 7 — テスト/仕上げ

* Minitest: モデル（バリデーション、集計、ユニーク制約）/ コントローラ（投票・リダイレクト）
* エッジケース（選択肢0/1、終了済み投票、締切）
* ✅: `bin/rails test` パス
* ✅: 使用API/記法が **Rails 8 Guides** に準拠しているか（`Rails.version` と突き合わせ）

## 5) ルール（必読）

* **Redis を追加しない**（Action Cable / Turbo Streams NG）
* 依存をむやみに増やさない（Minitest ベース）
* Fat Controller/Model を避け、**Form Object**や**Query**は必要になったら最小導入
* **アクセシビリティ**と**エラーハンドリング**を常に考慮
* 1コミットの粒度は小さく、**1目的/1差分**に絞る（ファイル跨ぎも最小限）
* Active Record の記法・APIは **Rails Guides v8** 準拠を厳守（旧記法は現行に置換）

## 6) コミット規約（🤖 + AI ログ）

### 6.1 コミット形式

* **AI が行うすべてのコミットは必ず**  
  **`🤖 <type>: <description>`** の形式で始めること。  

  - `🤖` 固定（AI由来であることを明示）  
  - `<type>` は **Conventional Commits** に準拠  
    - `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore` など  
  - `<description>` は 50字以内の要約 

* **例**  
  - `🤖 feat: add Poll model and migration`  
  - `🤖 fix: validate voter_hash uniqueness`  
  - `🤖 docs: update README with setup steps`    

### 6.2 メッセージ構成

````
🤖<type>: 要約（50字以内）

agent:
  model: "<model>@<version>"     # ★出所が確実に特定できるときだけ記載。曖昧なら "unknown"
  memory:
    # Claude: memory 参照
    # Codex / Gemini: system prompt / デフォルト instruction
    refs: ["AGENTS.md", "docs/checklist.md"]
prompt:
  excerpt: |-
    <今回のコミットを直接生んだ“直近の差分指示”の先頭200字>
  actor: user|agent|file|script  # ★出所が確実に特定できるときだけ記載。曖昧なら "unknown"
response:
  summary: |-
    <出力の要約 3点まで>
  code_changes_summary: "files=N, +LOC=, -LOC="
tokens:
  input: <int>                   # Inputに利用したトークン量を記載
  output: <int>                  # Outputに利用したトークン量を記載
context:
  remaining_tokens: <int>        # 実行時点で残っていたコンテキスト量
  compacted: true|false          # compact が走ったかどうか
  compact_reason: "<text>"       # 任意。compactが走った場合の理由  
runtime:
  cost: <float|null>             # 任意。未知なら未記載
  elapsed_sec: <float|null>      # 任意。全体の経過時間（wall clock）
  inference_sec: <float|null>    # モデル推論にかかった時間
  tokenization_sec: <float|null> # 入力テキストのトークナイズ処理
  streaming_sec: <float|null>    # 出力がストリーミングされる時間
  prep_sec: <float|null>         # プロンプト整形など前処理
  postproc_sec: <float|null>     # 出力要約/整形など後処理
  latency_sec: <float|null>      # 最初のレスポンスが返るまでの時間
  throughput_tok_per_sec: <float|null> # 出力性能（tokens/sec）
  tool_sec_total: <float|null>   # ツール呼び出しにかかった合計時間
  tool_breakdown:                # ツール毎の実行時間内訳（必要な場合のみ）
    - name: "<tool_name>"
      sec: <float>
  tools_used: []                 # 任意。使っていなければ空配列 or 未記載
````

* **注意**: 認証情報・秘密は絶対にログへ書かない。長文は先頭を抜粋。

## 7) 役割別プロンプト（ミニプロンプト集）

> それぞれ **現在のフェーズ/受け入れ基準** を先頭に貼り、**差分最小**で作業すること。

### Architect（設計）

* 目的: モデル/ルーティング/責務の分割を提案し、採用案を最短で記述
* 出力: ERD（テキスト）、列と制約、インデックス理由、ユースケース
* 注意: Redis/Streams 不使用、SQLite で表現可能な制約に限定

### Implementer（実装）

* 目的: スキャフォールドを使い倒すが、**生成物を積極的に削る**（必要最小）
* 出力: コントローラ/ビュー/ヘルパ/ルート/バリデーション
* 注意: 1コミット＝1目的（例：マイグレーションだけ→コントローラ→ビュー…）

### UI/UX（Tailwind）

* 目的: Card/ボタン/フォーム/結果バーのスタイル
* 出力: クラス付与と軽いパーシャル分割
* 注意: コントラスト/フォーカスリング、フォームエラー表示

### Tester（Minitest）

* 目的: モデル・コントローラの正常/異常パス
* 出力: 最小グリーン → 代表的境界値を追加
* 注意: 外部依存無しで再現可能に

### Scribe（ドキュメント）

* 目的: README に「起動/投票/結果確認/制約」を簡潔追記

## 8) ルーティング方針（MVP）

```rb
# config/routes.rb
root "polls#index"
resources :polls, param: :slug do
  member do
    post :open
    post :close
  end
  resources :votes, only: [:create]
end
```

## 9) セキュリティ/プライバシー

* PII を保存しない。`voter_hash` は不可逆。Cookie は署名付き。
* CSRF 対策は既定のまま（フォームヘルパー使用）。
* 強制 HTTPS 前提想定（本番時）。

## 10) テスト項目（サンプル）

* **Poll**: `status` 遷移、`ends_at` 超過の判定、`slug` 一意
* **Choice**: `label` 必須、`poll` との整合
* **Vote**: `open?` 時のみ作成可、`choice.poll == poll` 必須、一意制約（`poll_id + voter_hash`）
* **Controller**: 正常投票→結果表示、二重投票→エラー、締切→投票不可

## 11) 比較のための評価表（チェックリスト）

* 設計: モデル/インデックス/一意性、命名、責務
* 実装: コード量 vs 可読性、Rails 慣習遵守、N+1 なし
* UI/UX: 一貫性、エラー表示、アクセシビリティ
* 品質: テスト網羅、境界条件
* ドキュメント/コミット: **ai\_log** の整備度、コミット粒度

## 12) 既知のトレードオフ / TODO

* Cookie + `voter_hash` は「**強固ではない**」重複抑止。将来ログイン導入で強化可。
* 多選択（複数選択）投票は **Phase 4+** で拡張（`Vote` の unique 条件/フォーム更新が必要）。
* 結果のバーは CSS のみ。将来はチャート導入も可（ただしビルド導入は慎重に）。
