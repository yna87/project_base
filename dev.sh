#!/bin/bash
# フロントエンドとバックエンドを同時に起動

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 関数定義
cleanup() {
    echo "サーバーを停止しています..."
    kill $BACKEND_PID
    kill $FRONTEND_PID
    exit
}

# Ctrl+Cのシグナルをトラップ
trap cleanup INT TERM

echo "バックエンドサーバーを起動しています..."
cd "$SCRIPT_DIR/backend" && bundle exec rackup -p 4567 & 
BACKEND_PID=$!

echo "フロントエンドサーバーを起動しています..."
cd "$SCRIPT_DIR/frontend" && yarn dev & 
FRONTEND_PID=$!

echo "開発サーバーが起動しました！"
echo "バックエンド: http://localhost:4567"
echo "フロントエンド: http://localhost:5173"

# プロセスが終了するまで待機
wait
