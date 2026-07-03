#!/usr/bin/env bash
set -euo pipefail

stack="${1:-}"
if [[ -z "$stack" || ! -f "$stack/compose.yml" || ! -f "$stack/.env" ]]; then
  echo "usage: $0 STACK (after copying STACK/.env.example to STACK/.env)" >&2
  exit 2
fi

if grep -Eq '(^|=)(CHANGE_ME|REPLACE_WITH|example-token|example-password)' "$stack/.env"; then
  echo "Refusing deployment: replace all placeholder values in $stack/.env" >&2
  exit 1
fi

docker compose --env-file "$stack/.env" -f "$stack/compose.yml" config --quiet
echo "$stack configuration passed preflight"

