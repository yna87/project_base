#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "マイグレーションしています..."
cd backend
bundle exec rails db:migrate

echo "マイグレーションが完了しました"
bundle exec rails db:migrate:status
