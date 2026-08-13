# ① ベースイメージ：Ruby 3.4.10 の公式イメージを使用
FROM ruby:3.4.10

# ② 環境変数：Bundler のインストール先を指定
ENV BUNDLE_PATH=/usr/local/bundle

# ③ 必要な Linux パッケージのインストール
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    postgresql-client \
    curl \
    gnupg2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ④ Node.js（LTS版）のインストール
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# ⑤ Yarn のインストール
RUN npm install -g yarn

# ⑥ アプリケーションのディレクトリを作成・作業ディレクトリに設定
WORKDIR /app

# ⑦ Gemfile と Gemfile.lock をコピーし、bundle install
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

# ⑧ アプリケーションコード全体をコピー
COPY . .

# ⑧-a コンテナ起動時のエントリーポイント設定
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# ⑧-b Rails サーバー起動コマンド（デフォルト）
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]