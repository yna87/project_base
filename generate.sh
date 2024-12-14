#!/bin/bash
# erd.mdからコードを自動生成

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "ソースコードを生成しています..."

cd scripts

python ./rb_generator.py
python ./ts_generator.py

cd ..

echo "ソースコードの生成が完了しました"

