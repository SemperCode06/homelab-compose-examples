#!/usr/bin/env bash
set -euo pipefail

for compose in */compose.yml; do
  stack="${compose%/compose.yml}"
  echo "Validating $stack"
  docker compose --env-file "$stack/.env.example" -f "$compose" config --quiet
done

./scripts/check-sanitization.sh
echo "All Compose and sanitization checks passed."
