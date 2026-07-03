#!/usr/bin/env bash
set -euo pipefail

fail_if_match() {
  local message="$1"
  local pattern="$2"
  shift 2

  if rg --quiet --pcre2 --hidden --glob '!.git/**' "$@" -- "$pattern" .; then
    echo "Sanitization check failed: $message" >&2
    echo "Inspect the working tree locally; matched content is hidden to keep logs clean." >&2
    exit 1
  fi
}

sensitive_name_pattern='(^|/)(\.env|acme\.json|id_rsa|id_ed25519|[^/]+\.(pem|key|pfx|sqlite|sqlite3))$'

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Check tracked and untracked commit candidates, but honor .gitignore.
  sensitive_file_present() {
    git ls-files --cached --others --exclude-standard | grep -Eq "$sensitive_name_pattern"
  }
else
  # Support reviewing a template before `git init` without scanning dependencies.
  sensitive_file_present() {
    find . \
      \( -type d \( -name .git -o -name .venv -o -name venv -o -name myenv \
                      -o -name __pycache__ -o -name .pytest_cache \) -prune \) -o \
      \( -type f \( -name '.env' -o -name '*.pem' -o -name '*.key' -o -name '*.pfx' \
                     -o -name 'acme.json' -o -name 'id_rsa' -o -name 'id_ed25519' \
                     -o -name '*.sqlite' -o -name '*.sqlite3' \) -print -quit \) \
      | grep -q .
  }
fi

if sensitive_file_present; then
  echo "Sanitization check failed: a secret or runtime-state filename is present." >&2
  exit 1
fi

fail_if_match "a private key is embedded in a tracked file" \
  '-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----' \
  --glob '!scripts/check-sanitization.sh'

fail_if_match "a value resembles a real access token" \
  '(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,})' \
  --glob '!scripts/check-sanitization.sh'

fail_if_match "a credential field contains a literal value instead of a placeholder or variable" \
  "(?im)^\\s*[A-Z0-9_-]*(?:PASSWORD|PASSWD|SECRET|TOKEN|API_KEY|PRIVATE_KEY)[A-Z0-9_-]*\\s*[:=]\\s*[\"']?(?!\\\$\\{|CHANGE_ME|REPLACE_WITH|EXAMPLE_|<)[A-Za-z0-9+/=_-]{8,}" \
  --glob '*.yml' --glob '*.yaml' --glob '*.env' --glob '*.env.example' \
  --glob '!scripts/check-sanitization.sh'

fail_if_match "a non-example email address is present" \
  '(?i)\b[A-Z0-9._%+-]+@(?!example\.(?:com|org|net)\b)[A-Z0-9.-]+\.[A-Z]{2,}\b' \
  --glob '!scripts/check-sanitization.sh'

fail_if_match "a host-specific home directory is present" \
  '(?:/home/[^/$ `{]+|/Users/[^/$ `{]+|[A-Z]:\\Users\\[^\\$% `{]+)' \
  --glob '!scripts/check-sanitization.sh'

fail_if_match "a backend URL contains a literal IP address" \
  "(?im)^\\s*(?:url|address)\\s*:\\s*[\"']?(?:https?|tcp)://(?:\\d{1,3}\\.){3}\\d{1,3}" \
  --glob '*.yml' --glob '*.yaml' \
  --glob '!scripts/check-sanitization.sh'

fail_if_match "an example host variable uses a non-example internet domain" \
  '(?im)^[A-Z0-9_]*(?:DOMAIN|HOST|HOSTNAME)\s*=\s*(?!localhost\b)(?!(?:[A-Z0-9_-]+\.)*example\.(?:com|org|net)\b)[A-Z0-9_-]+\.[A-Z]{2,}\s*$' \
  --glob '*.env.example' \
  --glob '!scripts/check-sanitization.sh'

echo "Sanitization checks passed."
