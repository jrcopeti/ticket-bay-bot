#!/usr/bin/env bash
# Host only. Mints a 1-hour GitHub App installation token for jrcopeti/ticket-bay and writes it
# as the gh login the sandbox mounts read-only. The App's private key never leaves ~/.config/github-app.
# Usage: mint-gh-token.sh read|write
set -euo pipefail
umask 077
cfg=~/.config/github-app
app_id=$(cat "$cfg/app-id"); inst_id=$(cat "$cfg/installation-id")
case "${1:-}" in
  read)  perms='{"contents":"read","pull_requests":"read"}' ;;
  write) perms='{"contents":"write","pull_requests":"write"}' ;;
  *) echo "usage: mint-gh-token.sh read|write" >&2; exit 2 ;;
esac

# A run killed before its revoke hook fired leaves its token here: revoke it before it's overwritten.
"$HOME/.hermes/agent-hooks/revoke-gh-token.sh" --now || true

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
now=$(date +%s)
header=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' $((now - 60)) $((now + 540)) "$app_id" | b64url)
sig=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -sign "$cfg/key.pem" | b64url)

token=$(curl -fsS -X POST \
  -H "Authorization: Bearer $header.$payload.$sig" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$inst_id/access_tokens" \
  -d "{\"repositories\":[\"ticket-bay\"],\"permissions\":$perms}" | jq -re .token)

cat > ~/.config/gh/hosts.yml.tmp <<YAML
github.com:
    oauth_token: $token
    git_protocol: https
    user: ticket-bay-bot[bot]
YAML
mv ~/.config/gh/hosts.yml.tmp ~/.config/gh/hosts.yml
