# FloorMap Seating Manager - 包括的なGitHub Issue作成プロンプト

このプロンプトをGitHub Copilotで使用して、段階的にissueを作成します。

---

## 使用方法

1. GitHub Copilotチャットを開く（VS Codeまたはgithub.com）
2. 以下の指示文をコピー＆ペーストする
3. Copilotが生成したissueのMarkdownをコピー
4. GitHubリポジトリの Issues セクションで「New Issue」から作成

---

## GitHub Copilot用プロンプト

```
以下の仕様でFloorMap Seating Manager（上面図管理システム）を最初から開発する場合、
段階的に実装するためのGitHub Issueを作成してください。

【プロジェクト概要】
- 名前: FloorMap Seating Manager
- 説明: 建物の上面図を管理し、座席のチェックイン・チェックアウト、リアルタイム更新を行うシステム
- 技術スタック: Rails 8.1.3、Inertia.js、React、PostgreSQL 15、Docker

【主な機能】
1. ユーザー認証・認可（Devise + 2FA）
2. ルーム/上面図管理（作成・編集・削除）
3. 座席管理（配置・ラベル付け・チェックイン・チェックアウト）
4. リアルタイム更新（ActionCable）
5. バックグラウンドジョブ（good_job、自動離席）
6. 権限管理（ルーム作成者・権限ユーザー）
7. 非ログインユーザー対応（訪問者機能）
8. CSV エクスポート
9. グリッド表示・スナップ機能
10. 図形描画機能

【要件】
- 10段階のPhaseで分割
- 各Phaseごとに複数のissueを作成
- issueは以下の形式で出力:

# [Phase X] Issue Title

## 説明
簡潔な説明（2-3文）

## 実装内容
- タスク1
- タスク2
- タスク3

## 受け入れ基準
- [ ] 条件1
- [ ] 条件2
- [ ] 条件3

## 関連Issue
- 関連するIssue（ある場合）

---

## 段階的実装計画

### Phase 1: プロジェクトセットアップ & 基本認証
Rails 8.1.3プロジェクトの初期構築、必要なGemの導入、認証機能の実装

### Phase 2: ユーザー認可・権限管理
Punditによる権限管理、ロール定義、権限ユーザー管理

### Phase 3: コア機能 - ルーム管理
ルームモデル、CRUD操作、トークンベースのアクセス管理

### Phase 4: コア機能 - 座席管理
座席モデル、チェックイン・チェックアウト、座席の配置管理

### Phase 5: フロントエンド基盤 - React & Inertia.js
Inertia.jsの設定、React コンポーネント構造、ルーティング

### Phase 6: UIコンポーネント - ルーム管理画面
ルーム一覧、作成・編集・削除フォーム、検索機能

### Phase 7: UIコンポーネント - エディタ・上面図表示
キャンバスコンポーネント、座席描画、図形ツール、グリッド表示

### Phase 8: リアルタイム更新 & WebSocket
ActionCable設定、座席更新の自動配信、リアルタイム通知

### Phase 9: バックグラウンドジョブ & 自動離席
good_jobセットアップ、自動離席ジョブ、スケジューリング

### Phase 10: 非ログインユーザー & 訪問者機能
セッションベースの訪問者管理、座席所有権の移譲、ログイン時の連携

### Phase 11: 高度な機能
CSV エクスポート、グリッド スナップ、共有機能、監査ログ

### Phase 12: 本番環境対応 & デプロイ
Docker最適化、render.yaml設定、CI/CDパイプライン、エラーハンドリング

---

## 生成するIssueの詳細指示

各Phase ごとに以下の内容のIssueを生成してください:

**Phase 1: プロジェクトセットアップ & 基本認証（6 Issues）**
1. Rails 8 プロジェクト初期化 & Gemfile設定
2. Devise & 2FA (devise-two-factor) のセットアップ
3. PostgreSQL セットアップ & マイグレーション
4. Docker & Docker Compose 設定
5. Vite & React 環境構築
6. Inertia.js 統合

**Phase 2: ユーザー認可・権限管理（4 Issues）**
1. Pundit による認可フレームワーク導入
2. User ロール定義（user/manager/admin）
3. RoomPermission モデル実装
4. Permission ユーザー管理機能

**Phase 3: コア機能 - ルーム管理（5 Issues）**
1. Room モデル & マイグレーション
2. ルーム作成・編集・削除機能
3. トークンベースのアクセス管理
4. ルーム一覧表示機能
5. ルーム詳細表示機能

**Phase 4: コア機能 - 座席管理（5 Issues）**
1. Seat モデル & マイグレーション
2. 座席のチェックイン機能
3. 座席のチェックアウト機能
4. 座席の位置・ラベル管理
5. 座席状態の表示

**Phase 5: フロントエンド基盤 - React & Inertia.js（4 Issues）**
1. Inertia.js ページコンポーネント構築
2. React ホットリロード設定
3. Tailwind CSS セットアップ
4. ページレイアウト・ナビゲーション

**Phase 6: UIコンポーネント - ルーム管理画面（4 Issues）**
1. ルーム一覧ページの実装
2. ルーム作成フォームの実装
3. ルーム編集画面の実装
4. ルーム検索・フィルタリング機能

**Phase 7: UIコンポーネント - エディタ・上面図表示（6 Issues）**
1. Canvas コンポーネント実装
2. 座席描画機能
3. 座席ドラッグ&ドロップ機能
4. 図形描画ツール（矩形・円・線）
5. グリッド表示機能
6. グリッド スナップ機能

**Phase 8: リアルタイム更新 & WebSocket（4 Issues）**
1. ActionCable チャネル設定
2. 座席更新のリアルタイム配信
3. 通知システム実装
4. Redis との連携（オプション）

**Phase 9: バックグラウンドジョブ & 自動離席（4 Issues）**
1. good_job セットアップ & Gem導入
2. CheckDailyAutoCheckoutJob 実装
3. ジョブスケジューリング設定
4. ジョブ実行ログ・監視

**Phase 10: 非ログインユーザー & 訪問者機能（5 Issues）**
1. 非ログインユーザーの座席チェックイン
2. セッションベースの訪問者管理
3. 訪問者から登録ユーザーへの座席所有権移譲
4. 訪問者の名前変更機能
5. 訪問者・登録ユーザーの権限統一

**Phase 11: 高度な機能（5 Issues）**
1. CSV エクスポート機能（座席・ルーム）
2. 共有リンク機能
3. 監査ログ・操作履歴（PaperTrail）
4. API ドキュメント（Swagger/rswag）
5. テストカバレッジ設定（RSpec + Factory Bot）

**Phase 12: 本番環境対応 & デプロイ（4 Issues）**
1. Docker イメージ最適化
2. render.yaml 設定 & Render.com デプロイ
3. エラーハンドリング & Sentry 統合
4. CI/CD パイプライン設定（GitHub Actions）

---

## Copilot出力結果の使い方

1. Copilotが生成した各Issueをコピーする
2. GitHubリポジトリ → Issues → New Issue
3. Markdown を貼り付けて作成
4. ラベル・マイルストーンを設定（自動または手動）
5. 段階的にassigneeを設定して実装開始

---

## カスタマイズオプション

必要に応じて以下を追加:
- 予想時間（Estimate）
- 優先度（Priority）
- タグ（Labels: backend, frontend, devops, bug, feature）
- マイルストーン（v0.1, v0.2, v1.0）
- 担当者（Assignee）

---

出力フォーマット:
すべてのIssueをMarkdown形式で、以下の順序で生成してください:
1. Phase番号とタイトル
2. 説明（簡潔に）
3. 実装内容（箇条書き）
4. 受け入れ基準（チェックボックス）
5. 関連Issue（前後のPhaseのみ）
6. ラベル提案（backend/frontend/devops）
```

---

## 補足: GitHub Copilot への質問パターン

### パターン1: 全Issueを一括生成
プロンプト内の「生成するIssueの詳細指示」セクションをコピーして、
「上記のIssueをすべてMarkdown形式で生成してください」と追加質問

### パターン2: 特定Phaseのみを詳細化
例: 「Phase 7 のUIコンポーネント - エディタの実装について、
さらに詳細なタスク分割とサブtaskを生成してください」

### パターン3: テンプレート化
生成されたIssueをテンプレートとして保存し、
GitHub の Issue Template として `.github/ISSUE_TEMPLATE/` に配置

---

## 実装例: Issue テンプレート

生成されたIssueの例:

```markdown
# [Phase 1] Rails 8 プロジェクト初期化 & Gemfile設定

## 説明
Rails 8.1.3で新規プロジェクトを作成し、
必要なGemをGemfileに追加してバンドルインストールを実行します。

## 実装内容
- `rails new floormap-seating-manager -d postgresql`でプロジェクト作成
- Devise, Pundit, good_job, Vite, Inertia など必要なGemを Gemfile に追加
- `bundle install` を実行
- README に技術スタック・セットアップ手順を記載
- git初期化 & 最初のコミット

## 受け入れ基準
- [ ] Rails 8.1.3プロジェクトが作成されている
- [ ] すべての必要なGemが Gemfile に記載されている
- [ ] `bundle install` が成功する
- [ ] `rails server` で起動確認できる
- [ ] git リポジトリが初期化されている

## ラベル
- backend
- setup
- phase-1

## マイルストーン
- v0.1
```

---

## Phase 別 マイルストーン設定推奨

| マイルストーン | Phases | 完成形 |
|---|---|---|
| v0.1 | Phase 1-4 | 基本的なCRUD機能 |
| v0.2 | Phase 5-7 | UI完成・エディタ動作 |
| v0.3 | Phase 8-9 | リアルタイム・バックグラウンドジョブ |
| v1.0 | Phase 10-12 | 本番環境対応・全機能完成 |

---

## チェックリスト: プロンプト実行時の確認

- [ ] GitHub Copilot にログインしている
- [ ] リポジトリの Issues セクションにアクセス可能
- [ ] 生成されたIssueの内容に誤りがないか確認
- [ ] ラベル・マイルストーン・優先度が適切に設定されている
- [ ] 関連Issueのリンクが正しい
- [ ] チームメンバーと優先度・スケジュールを調整
- [ ] 実装開始前に Phase 1-2 を確認・完了

---

生成されたIssueをぜひGitHubで管理し、段階的な開発を進めてください！
