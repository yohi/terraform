#!/bin/bash

# S3バケット・プレフィックス存在確認スクリプト
# 使用方法: ./s3_bucket_check.sh <bucket_name> [auto_create_bucket] [prefix]
# 引数:
#   bucket_name: S3バケット名（必須）
#   auto_create_bucket: バケットが存在しない場合に自動作成するかどうか（"true"/"false"、デフォルト: "false"）
#   prefix: 確認対象のプレフィックス（オプション）

set -euo pipefail

BUCKET_NAME=$1
AUTO_CREATE_BUCKET=${2:-"false"}
PREFIX=${3:-""}

if [ -z "$BUCKET_NAME" ]; then
    echo "エラー: バケット名が指定されていません" >&2
    echo "使用方法: $0 <bucket_name> [auto_create_bucket] [prefix]" >&2
    echo "  bucket_name: S3バケット名（必須）" >&2
    echo "  auto_create_bucket: バケット自動作成フラグ（\"true\"/\"false\"、デフォルト: \"false\"）" >&2
    echo "  prefix: 確認対象のプレフィックス（オプション）" >&2
    echo '{"bucket_exists": "false", "action": "error", "bucket_name": "", "message": "bucket name not provided"}'
    exit 1
fi

# S3バケットの存在確認
check_bucket_exists() {
    aws s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null 2>&1
    return $?
}

# S3プレフィックスの存在確認
check_prefix_exists() {
    if [ -n "$PREFIX" ]; then
        # コマンドの終了ステータスを保持するため、直接実行して結果を確認
        aws s3 ls "s3://$BUCKET_NAME/$PREFIX" >/dev/null 2>&1
        return $?
    else
        return 0  # プレフィックスが指定されていない場合はチェックしない
    fi
}

# バケットが存在するかチェック
if check_bucket_exists; then
    # プレフィックスの存在確認（指定されている場合）
    if [ -n "$PREFIX" ]; then
        if check_prefix_exists; then
            echo "S3バケット '$BUCKET_NAME' は既に存在します。" >&2
            echo "S3プレフィックス '$PREFIX' は既に存在します。" >&2
            echo "既存のバケットとプレフィックスを使用します。" >&2
            echo '{"bucket_exists": "true", "prefix_exists": "true", "action": "use_existing", "bucket_name": "'$BUCKET_NAME'", "prefix": "'$PREFIX'"}'
        else
            echo "エラー: S3プレフィックス '$PREFIX' が存在しません" >&2
            echo "バケット '$BUCKET_NAME' は存在しますが、指定されたプレフィックスにデータがありません" >&2
            echo '{"bucket_exists": "true", "prefix_exists": "false", "action": "error", "bucket_name": "'$BUCKET_NAME'", "prefix": "'$PREFIX'", "message": "prefix does not exist"}'
            exit 1
        fi
    else
        echo "S3バケット '$BUCKET_NAME' は既に存在します。" >&2
        echo "既存のバケットを使用します。" >&2
        echo '{"bucket_exists": "true", "prefix_exists": "true", "action": "use_existing", "bucket_name": "'$BUCKET_NAME'"}'
    fi
else
    # AUTO_CREATE_BUCKETが"true"の場合、バケットを自動作成
    if [ "$AUTO_CREATE_BUCKET" = "true" ]; then
        echo "S3バケット '$BUCKET_NAME' が存在しないため、作成します..." >&2

        # バケットを作成
        if aws s3api create-bucket --bucket "$BUCKET_NAME" --region $(aws configure get region) --create-bucket-configuration LocationConstraint=$(aws configure get region) 2>/dev/null; then
            echo "S3バケット '$BUCKET_NAME' が正常に作成されました。" >&2
            echo '{"bucket_exists": "true", "prefix_exists": "true", "action": "created", "bucket_name": "'$BUCKET_NAME'"}'
        else
            # us-east-1リージョンの場合はLocationConstraintを指定しないで再試行
            if aws s3api create-bucket --bucket "$BUCKET_NAME" --region $(aws configure get region) 2>/dev/null; then
                echo "S3バケット '$BUCKET_NAME' が正常に作成されました。" >&2
                echo '{"bucket_exists": "true", "prefix_exists": "true", "action": "created", "bucket_name": "'$BUCKET_NAME'"}'
            else
                echo "エラー: S3バケット '$BUCKET_NAME' の作成に失敗しました" >&2
                echo '{"bucket_exists": "false", "prefix_exists": "false", "action": "error", "bucket_name": "'$BUCKET_NAME'", "message": "bucket creation failed"}'
                exit 1
            fi
        fi
    else
        echo "エラー: S3バケット '$BUCKET_NAME' は存在しません" >&2
        echo "事前にバケットを作成するか、auto_create_bucket引数に'true'を指定してください" >&2
        echo '{"bucket_exists": "false", "prefix_exists": "false", "action": "error", "bucket_name": "'$BUCKET_NAME'", "message": "bucket does not exist"}'
        exit 1
    fi
fi
