#!/bin/bash
set -e

# Rails サーバーの PID ファイルが残っていたら削除
rm -f /app/tmp/pids/server.pid

# CMD で渡されたコマンドを実行
exec "$@"