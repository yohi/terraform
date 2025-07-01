#!/bin/bash

# Input parameter: database name
DATABASE_NAME="$1"

if [ -z "$DATABASE_NAME" ]; then
    echo '{"error": "Database name not provided"}' >&2
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo '{"exists": "false", "error": "AWS credentials not configured"}' >&2
    exit 1
fi

# Check if the database exists
if aws glue get-database --name "$DATABASE_NAME" >/dev/null 2>&1; then
    echo '{"exists": "true"}'
else
    echo '{"exists": "false"}'
fi
