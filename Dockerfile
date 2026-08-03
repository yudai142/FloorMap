FROM ruby:3.3.0-alpine

# 必要なパッケージをインストール
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    nodejs \
    npm \
    yarn

# アプリケーションディレクトリを作成
WORKDIR /app

# Gemfileをコピー
COPY Gemfile Gemfile.lock* ./

# Gemをインストール
RUN bundle install

# アプリケーションコードをコピー
COPY . .

# ポート3000を公開
EXPOSE 3000

# デフォルトコマンド
CMD ["bash", "-c", "bundle exec rails db:prepare && bundle exec rails server -b 0.0.0.0"]
