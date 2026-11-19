#!/usr/bin/env bash
# Every 10 min, as a Hermes no-agent job on ticket-bay-bot: print the requests squid denied since the
# last run. Squid is the sandbox's only way out, so a denial means something in it tried to reach a
# host off the allowlist: in a bug-loop or pr-triage run, most likely an injection phoning home.
# Silent when there are none. The first run only takes the baseline.
set -u
STATE=${SQUID_DENIALS_STATE:-$HOME/.squid-denials.seen}
MAX=20
readlog() {
  if [ -n "${SQUID_LOG:-}" ]; then cat "$SQUID_LOG"; else docker exec egress-squid-1 cat /var/log/squid/access.log; fi
}
# The x keeps the trailing newline, so a line squid is still writing can be left for the next run.
log=$(readlog 2>&1 && echo x) || { echo "⚠️ squid-denials: can't read squid's log: $log"; exit 0; }
log=${log%x}
total=$(printf '%s' "$log" | wc -l | tr -d ' ')
first=$(head -n 1 <<<"$log")
if [ ! -f "$STATE" ]; then printf '%s\n%s\n' "$total" "$first" > "$STATE"; exit 0; fi
{ read -r seen; read -r seen_first; } < "$STATE"
# A different first line or fewer lines: squid's log was recreated, so read it from the start.
[ "$first" != "${seen_first:-}" ] || [ "$total" -lt "$seen" ] && seen=0
printf '%s\n%s\n' "$total" "$first" > "$STATE"
# Squid's native format: time elapsed client code/status bytes method URL ...
denied=$(printf '%s' "$log" | head -n "$total" | tail -n +$((seen + 1)) | while read -r ts _ _ code _ method url _; do
  # TCP_DENIED_ABORTED and the like: the client hung up before squid answered, still a denial.
  [[ $code == TCP_DENIED[/_]* ]] || continue
  # In a code span: Discord doesn't preview it (which would finish the leak) or ping from it.
  echo "$(date -u -d "@${ts%.*}" '+%F %H:%M' 2>/dev/null || echo "$ts") UTC  $method \`${url//\`/}\`"
done)
[ -z "$denied" ] && exit 0
n=$(grep -c '' <<<"$denied")
echo "🚫 squid blocked $n request(s) from ticket-bay-bot's sandbox (off the allowlist):"
head -n $MAX <<<"$denied"
[ "$n" -gt $MAX ] && echo "… and $((n - MAX)) more: docker exec egress-squid-1 grep TCP_DENIED /var/log/squid/access.log"
exit 0
