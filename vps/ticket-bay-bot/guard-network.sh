#!/usr/bin/env bash
# Hermes pre_tool_call guard for Telma (terminal tool). Ported from <repo>'s
# .claude/hooks/guard-network.sh (course M2/M7). Telma has no webhook: Hermes
# delivers results itself, so the agent never needs curl/wget. This is the layer that
# does not depend on the model obeying the prompt. Exit 2 = block, stderr = reason.
block() { echo "Blocked by guard-network: $1" >&2; exit 2; }

# Without jq the guard would read an empty command and let everything through: fail closed.
command -v jq >/dev/null || block "jq is not installed on the host (apt install jq)"
cmd=$(jq -r '.tool_input.command // ""')

# 1. No environment dumps.
if grep -Eq '(^|[;&|( ]|\$\()(env|printenv|export -p|set)([ ;&|)]|$)|/proc/[^ ]*/environ' <<<"$cmd"; then
  block "commands that print the environment are not allowed"
fi

# 2. No reading the secrets the sandbox can see (the gh token, the mail password).
if grep -Eq 'hosts\.yml|gh auth token|/opt/secrets|app-password' <<<"$cmd"; then
  block "reading credential files is not allowed"
fi

# 3. No raw network tools: git, gh and npm cover everything the job needs.
if grep -Eq '(^|[;&|( ])(curl|wget|nc|ncat|telnet)( |$)' <<<"$cmd"; then
  block "raw network tools (curl, wget, nc) are not allowed; use git, gh or npm"
fi

# 4. A literal URL only inside a git / gh / npm / npx command.
if grep -Eq 'https?://' <<<"$cmd"; then
  while IFS= read -r seg; do
    if grep -Eq 'https?://' <<<"$seg" && ! grep -Eq '^[[:space:]]*(git|gh|npm|npx)[[:space:]]' <<<"$seg"; then
      block "a literal URL is only allowed in git, gh and npm commands"
    fi
  done < <(sed -E 's/(&&|\|\||;|\|)/\n/g' <<<"$cmd")
fi

# 5. npm and npx only by name: Hermes's package scanner checks commands that start with npm/npx,
#    so `node …/npm-cli.js ci` or a full path to npm's bin folder skips the scan.
if grep -Eq '(npm|npx)-cli\.js|node_modules/npm/bin/' <<<"$cmd"; then
  block "run npm as \`npm …\` (npx as \`npx …\`), not through npm-cli.js or npm's bin folder"
fi

exit 0
