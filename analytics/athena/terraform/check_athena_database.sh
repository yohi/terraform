#!/bin/bash

# 入力パラメータ: データベース名
DATABASE_NAME="$1"

if [ -z "$DATABASE_NAME" ]; then
    echo '{"error": "Database name not provided"}' >&2
    exit 1
fi

# AWS認証情報が設定されているかチェック
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo '{"exists": "false", "error": "AWS credentials not configured"}' >&2
    exit 1
fi

# データベースが存在するかチェック
if aws glue get-database --name "$DATABASE_NAME" >/dev/null 2>&1; then
    echo '{"exists": "true"}'
else
    echo '{"exists": "false"}'
fi
