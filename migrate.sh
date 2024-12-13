#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# backendディレクトリの存在確認
if [ ! -d "backend" ]; then
    echo "エラー: backendディレクトリが見つかりません"
    exit 1
fi

echo "マイグレーションしています..."
cd backend || exit 1

if bundle exec rails db:migrate; then
    echo "マイグレーションが完了しました"
    bundle exec rails db:migrate:status
else
    echo "マイグレーションに失敗しました"
    exit 1
fi