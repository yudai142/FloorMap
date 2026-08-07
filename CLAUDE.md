# FloorMap - Claude Code ガイド

## プロジェクト概要

**プロジェクト名:** FloorMap（フロアマップ）
**説明:** オフィス・施設の座席配置管理・リアルタイム共有アプリケーション
**対象ユーザー:** 企業・施設の受付・管理者

**主な機能:**
- 座席・ルームの配置図をWebで管理・共有
- ユーザーの着席・離席リアルタイム同期
- QRコードによるセルフチェックイン
- 権限管理（訪問者・登録ユーザー・管理者）
- 分析ダッシュボード（座席利用率・滞在時間など）

---

## 技術スタック

### バックエンド
- **Framework:** Rails 8.1.3
- **Database:** PostgreSQL 15
- **Cache/Queue:** Redis 7
- **ジョブ:** good_job
- **認証:** Devise + devise-two-factor (TOTP 2FA)
- **認可:** Pundit
- **リアルタイム:** ActionCable

### フロントエンド
- **JavaScript:** Importmap-Rails
- **CSS:** TailwindCSS v4
- **UI Components:** Hotwire (Turbo, Stimulus)

### デプロイ・インフラ
- **Containerization:** Docker & Docker Compose
- **デプロイ先:** Render.com
- **CI/CD:** GitHub Actions

### 開発・テスト
- **Testing:** RSpec + Factory Bot
- **コード品質:** Rubocop + Brakeman
- **Observability:** Sentry

---

## プロジェクト構造

```
FloorMap/
├── app/
│   ├── models/          # User, Room, Seat, Sessionなど
│   ├── controllers/     # APIエンドポイント・ビューコントローラ
│   ├── views/           # ERB テンプレート
│   ├── jobs/            # good_job ジョブ
│   └── channels/        # ActionCable チャネル
├── config/
│   ├── routes.rb        # ルーティング定義
│   ├── database.yml     # DB接続設定
│   └── environments/    # 環境別設定
├── db/
│   ├── migrate/         # マイグレーションファイル
│   └── seeds.rb         # シードデータ
├── spec/                # テスト
├── docker-compose.yml   # Docker開発環境
├── Dockerfile.dev       # 開発用Dockerfile
├── Gemfile             # Ruby dependencies
└── CLAUDE.md           # このファイル
```

---

## 現在の実装状況

### ✅ 完了したPhase（4/7）

#### Phase 1: 基盤・認証・インフラ
- ✅ **#22** Docker & Docker Compose 設定
  - PostgreSQL 15, Redis 7 をコンテナで構築
  - 開発環境完全構築
  
- ✅ **#19** Rails 8.1.3 プロジェクト初期化 & Gemfile 設定
  - Rails 新規プロジェクト生成
  - 必須 gem 161 個をインストール
  
- ✅ **#20** Devise & 2FA (devise-two-factor) のセットアップ
  - ユーザー認証機能実装
  - TOTP 2段階認証対応
  - ログイン・登録ビュー自動生成
  
- ✅ **#21** PostgreSQL セットアップ & マイグレーション
  - DB テーブル構造定義
  - Users テーブルマイグレーション完了
  - db:prepare スクリプト動作確認

### ⏳ 実装予定（Phase 1 残り）

- **#23** Vite & React 環境構築（次のターゲット）
  - React コンポーネント開発環境
  - HMR (Hot Module Replacement) 設定
  
- **#24** Inertia.js 統合
  - Rails ↔ React 間のデータバインディング
  - シングルページアプリケーション化
  
- **#72** render.yaml 設定 & Render.com デプロイ
  - 本番環境デプロイ設定
  - GitHub Actions 自動デプロイ

### 📋 その他Phase（Phase 2～12）
- Phase 2: ユーザーロール・権限管理
- Phase 3: ルーム・座席 CRUD 機能
- Phase 4: チェックイン・チェックアウト機能
- Phase 5: React UI コンポーネント
- Phase 6: ルーム一覧・検索機能
- Phase 7: Canvas 座席配置図
- Phase 8: ActionCable リアルタイム同期
- Phase 9: 自動チェックアウトジョブ
- Phase 10: 訪問者管理機能
- Phase 11: テスト・ドキュメント・監視
- Phase 12: CI/CD・デプロイ自動化

---

## ユーザーの指示・要望

### スケジュール
- **期間:** 8週間（2026年8月2日～9月26日）
- **スプリント:** 週単位で分割
- **総ストーリーポイント:** 361点
- **本リリース:** 最小限の機能を8週間で完成
- **本リリース後の拡張機能:** Phase 13～17（別途計画）

### 開発スタイル
1. **段階的コミット:** 各実装ステップで日本語コメント付きコミット
2. **co-authors 非使用:** コミットメッセージに co-authored-by を含めない
3. **Issue クローズ:** 実装完了時に GitHub Issue をクローズ
4. **Docker 優先:** ローカルセットアップより Docker 環境で開発

### 本リリース後の実装予定

以下は Phase 13～17 として計画中：

- **Phase 13:** セルフチェックイン（QRコード機能）
- **Phase 13:** 分析ダッシュボード（座席利用率・平均滞在時間）
- **Phase 14:** 座席メモ・タグ機能（禁煙席・VIP席などの属性）
- **Phase 14:** Slack 通知連携
- **Phase 15:** レイアウトテンプレート機能・コミュニティ
- **Phase 16:** モバイルネイティブアプリ（iOS/Android）
- **Phase 17:** 業務用途への展開（飲食店・イベント会場向けUI）

---

## 開発ルール・ベストプラクティス

### コミット
- **段階的コミット:** 機能ごと・ステップごとに分けてコミットする（一度にまとめない）
- **コミットメッセージは日本語**
- **Co-Authored-By は絶対に含めない**

```bash
# 段階的にコミット
git add [関連するファイルのみ]
git commit -m "機能1の実装タイトル

詳細説明
- 実装した内容
次ステップ: ~"

# 別の機能は別のコミット
git add [別の関連ファイル]
git commit -m "機能2の実装タイトル

詳細説明
- 実装した内容
次ステップ: ~"

# ⚠️ Co-Authored-By は絶対に含めない
# ✗ Co-Authored-By: Claude <noreply@anthropic.com>
```

### ブランチ戦略
- `main`: 本リリース用ブランチ
- `feature/NN-phase-setup`: フェーズ別実装ブランチ
- PR 作成時に issue リンク

### PR・マージプロセス
- **テストコード先行:** テストコードを作成してからPRを作成
- **マージ前の実装待機:** PRを作成した後、ユーザーからの明示的なマージ指示まで待機
- **マージは指示のみ:** 「実装してマージして」などのユーザー指示を受けた場合のみマージ

### テスト・デプロイ

#### ローカルでのテスト実行
```bash
# 全テスト実行
docker-compose run --rm -e DATABASE_URL="postgresql://postgres:postgres@db:5432/floormap_test" -e RAILS_ENV=test web bundle exec rspec

# 特定ファイルのみ実行
docker-compose run --rm -e RAILS_ENV=test web bundle exec rspec spec/models/user_spec.rb

# セキュリティチェック
docker-compose run --rm web bundle exec brakeman -q -z
docker-compose run --rm web bundle exec bundler-audit check --update

# リント チェック
docker-compose run --rm web bundle exec rubocop
```

#### マージ条件（GitHub PR）
⚠️ **重要: PRのマージは明示的な指示があるまで行わない**

PRが main にマージされるには、以下の全項目を満たす必要があります：

1. **GitHub Actions テスト合格**
   - 全 RSpec テスト: 0 failures
   - Brakeman セキュリティチェック: 合格
   - Rubocop リント: 合格
   
2. **テストカバレッジ**
   - Models: 100% （User）
   - Controllers: 100% （Pages）
   - 総テスト数: 15 examples 以上
   
3. **本リリース機能の確認**
   - Docker で動作確認（`docker-compose up`）
   - ユーザー登録・ログイン動作確認
   - 2FA (TOTP) 機能確認

4. **本番環境テスト**
   - Render.com へのデプロイ テスト
   - 本番 PostgreSQL へのマイグレーション確認

5. **ユーザーからのマージ指示**
   - PR作成後、ユーザーから明示的なマージ指示がある場合のみマージ

#### 自動デプロイ
- main ブランチへのマージ後、GitHub Actions が自動実行
- テスト合格後、Render.com に自動デプロイ

### UI・UXデザイン
- **各ページの実装時は Figma のデザインを参照すること**
  - Figma で作成したデザイン選択肢から、実装対象のデザインを確認
  - React コンポーネント実装前に、ビジュアル・レイアウト・カラースキームを確定
  - TailwindCSS のユーティリティクラスで、デザイン仕様を忠実に再現
- 色・余白・フォントサイズ は Figma の定義に準ずる
- レスポンシブデザイン（モバイル・タブレット・デスクトップ）は Figma で複数ブレークポイントを確認

### ファイル構成の原則
- 既存ファイルは Edit ツール（差分のみ）
- 新規ファイルは Write ツール（全体作成）
- 不要なファイルは削除（`git rm`）
- Documentation は README.md か CLAUDE.md に記載

---

## よく使うコマンド

### Rails
```bash
# マイグレーション実行（Docker 内）
docker-compose run --rm web bundle exec rails db:migrate

# サーバー起動
docker-compose up

# コンソール
docker-compose run --rm web bundle exec rails console

# 新しい model/controller 生成
bundle exec rails generate model/controller [Name]
```

### テスト
```bash
# RSpec テスト実行
bundle exec rspec spec/

# 特定ファイルのテスト
bundle exec rspec spec/models/user_spec.rb
```

### Git
```bash
# ブランチ作成・切替
git checkout -b feature/NN-phase-setup

# 段階的コミット
git add [files]
git commit -m "タイトル"

# プッシュ
git push -u origin feature/NN-phase-setup

# issue クローズ
gh issue close [issue_number] --comment "実装完了..."
```

---

## 次のアクション

**次に実装すべき issue:**
1. **#23** Vite & React 環境構築
2. **#24** Inertia.js 統合  
3. **#72** render.yaml & Render.com デプロイ

**実装前にチェックすること:**
- 最新のブランチからプル（`git pull origin feature/01-phase-setup`）
- Docker イメージがビルドされているか確認
- 新しい gem を追加する場合は `Gemfile` → `bundle install`
- マイグレーション必要な場合は `db:migrate` を実行

---

## 重要な注意事項

⚠️ **環境変数・シークレット**
- `config/master.key`, `.env` ファイルを git に含めない
- GitHub Actions のシークレット設定は UI で管理

⚠️ **データベース**
- ローカル DB は PostgreSQL が必要（Docker で代用推奨）
- マイグレーション前に必ずバックアップ

⚠️ **本番環境**
- Render.com にデプロイ前に全テスト実行
- `RAILS_ENV=production` で環境変数設定
- RAILS_MASTER_KEY を Render 環境変数に設定

---

**最終更新:** 2026年8月6日
**Phase 1 PR:** #92
**作成者:** Claude Code
**バージョン:** 1.0
