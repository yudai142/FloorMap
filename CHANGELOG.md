# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-06

### Added
- **Canvas SVG エディタ** - 座席配置図を自由に描画・編集できるUI
- **座席の自由配置** - 座標ベース（position_x/position_y）での座席配置
- **リアルタイム同期** - ActionCable によるリアルタイム座席状況同期
- **React ベース管理画面** - Inertia.js による React フロントエンド
- **ユーザー認証** - Devise & 2FA (TOTP) による認証機能
- **権限管理** - Pundit による役割ベースの権限管理
- **チェックイン/チェックアウト** - 座席のクリックによる着席・離席管理
- **ルーム管理** - 座席配置図の作成・編集・削除
- **Docker 開発環境** - PostgreSQL, Redis を含む完全な開発環境
- **GitHub Actions CI/CD** - テスト、リント、セキュリティスキャン自動化
- **Render.com デプロイ** - 自動デプロイパイプライン

### MVP特徴
- URLを開くだけで着席状況を一目で把握できる利便性
- カジュアルな集まり（勉強会・もくもく会・サークル活動）での使用対応
- リアルタイム同期によるシームレスなユーザー体験
- 将来的な店舗・施設向け拡張を視野に入れた設計

### Technology Stack
- **Backend**: Rails 8.1.3, PostgreSQL 15, Redis 7, good_job
- **Frontend**: React, TailwindCSS v4, Inertia.js, Hotwire
- **Real-time**: ActionCable (WebSocket)
- **Testing**: RSpec, Factory Bot, System Tests
- **Security**: Brakeman, bundler-audit, npm audit
- **Deployment**: Docker, GitHub Actions, Render.com

### 次のマイルストーン（Phase 13～17）
- QRコードセルフチェックイン機能
- 分析ダッシュボード（座席利用率・平均滞在時間）
- 座席メモ・タグ機能
- Slack 通知連携
- レイアウトテンプレート機能
- モバイルネイティブアプリ（iOS/Android）
- 業務用途への展開

---

## リリース確認項目

### 機能検証
- [x] ルーム作成・編集・削除
- [x] 座席配置図キャンバス描画
- [x] 座席の自由配置・移動・削除
- [x] ユーザーチェックイン/チェックアウト
- [x] リアルタイム座席同期
- [x] 権限管理（user/manager/admin）
- [x] Devise ユーザー認証
- [x] 2FA (TOTP) 認証

### テスト・品質
- [x] RSpec テスト: 全合格
- [x] Rubocop リント: 全合格
- [x] Brakeman セキュリティスキャン: 全合格
- [x] npm audit: 全合格
- [x] System テスト: 実施完了

### デプロイ・インフラ
- [x] Docker Compose 開発環境
- [x] GitHub Actions CI/CD パイプライン
- [x] Render.com 本番環境設定
- [x] PostgreSQL マイグレーション対応

---

**Release Date**: 2026年9月6日
**Service URL**: https://floormap-seating-manager.onrender.com
**Demo Room**: https://floormap-seating-manager.onrender.com/rooms/vNx9WWHZdCHynuJVMp3bdGdb
