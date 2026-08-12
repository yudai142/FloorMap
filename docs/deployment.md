# Render.com デプロイメント ガイド

## 概要

FloorMap は Render.com にデプロイされます。このドキュメントでは、デプロイ設定と手順について説明します。

## 必須環境変数

Render.com ダッシュボード の Environment 設定に以下を追加してください：

### データベース
- `DATABASE_URL`: PostgreSQL 接続文字列（Render で自動生成）

### Redis キャッシュ
- `REDIS_URL`: Redis 接続文字列（Render で自動生成）

### Rails 設定
- `RAILS_ENV`: `production`
- `RAILS_LOG_TO_STDOUT`: `true`
- `RAILS_SERVE_STATIC_FILES`: `true`
- `RAILS_MASTER_KEY`: `config/master.key` の内容

### エラートラッキング
- `SENTRY_DSN`: Sentry プロジェクトの DSN
  - [sentry.io](https://sentry.io) で新規プロジェクトを作成
  - DSN をコピーして設定

## デプロイプロセス

### 1. GitHub との連携（推奨）

```bash
# Render ダッシュボードで新規 Web Service を作成
# Repository: yudai142/FloorMap
# Branch: main
# Build Command: bundle install && bundle exec rails assets:precompile && bundle exec rails db:migrate
# Start Command: bundle exec puma -t 5:5 -p 3000
```

### 2. デプロイトリガー

main ブランチへのマージ時に自動デプロイが開始されます：

```bash
# ローカルで変更をコミット
git add .
git commit -m "Feature: ..."

# main にプッシュ（PR でマージされるか、直接プッシュ）
git push origin main

# Render.com が自動的にデプロイを開始
# ダッシュボードで進捗を確認
```

## デプロイ後の検証

### ヘルスチェック

```bash
# アプリケーションの状態確認
curl https://floormap.onrender.com/up

# 期待される応答:
# 200 OK with { "status":"ok" }
```

### ログ確認

```bash
# Render ダッシュボード → Logs で確認
# または、Render CLI:
render logs --service=floormap-web
```

### データベースマイグレーション

デプロイ時に自動実行されます。手動実行が必要な場合：

```bash
# Render Shell から実行
bin/rails db:migrate
```

## トラブルシューティング

### デプロイ失敗

1. ビルドログを確認
   - `bundle install` エラー → Gemfile 依存関係を確認
   - マイグレーションエラー → db:migrate ログを確認

2. アプリケーション起動エラー
   - `puma` ポート設定を確認
   - 環境変数が正しく設定されているか確認

### パフォーマンス問題

1. Redis キャッシュが有効か確認
2. データベースクエリを最適化
3. Sentry でエラーを監視

## セキュリティチェック

- [ ] RAILS_MASTER_KEY が安全に保管されている
- [ ] SENTRY_DSN が設定されている
- [ ] DATABASE_URL が暗号化されている
- [ ] SSL/HTTPS が有効
- [ ] CORS 設定が正しい

## ロールバック手順

Render.com ダッシュボック from Deployments:

1. 以前のデプロイを選択
2. "Redeploy" をクリック
3. ログで確認

または GitHub で:

```bash
git revert <commit-hash>
git push origin main
```

## 本番環境監視

### Sentry でのエラートラッキング

- [sentry.io](https://sentry.io) ダッシュボードにアクセス
- Issue を確認して原因を特定
- スタックトレースで デバッグ

### ログ分析

```bash
# 最新 100 行を表示
render logs --service=floormap-web -n 100

# リアルタイム監視
render logs --service=floormap-web -f
```

## リソース管理

### CPU & メモリ

- Starter プラン: 0.5 CPU, 512 MB RAM
- 必要に応じて Standard プランへアップグレード

### ストレージ

- PostgreSQL: 2.5 GB（Starter）
- 定期的にバックアップを取得

## 参考リンク

- [Render.com ドキュメント](https://render.com/docs)
- [Rails デプロイメントガイド](https://guides.rubyonrails.org/command_line.html#rails-dbmigrate)
- [Sentry Rails ガイド](https://docs.sentry.io/platforms/ruby/guides/rails/)
