#!/usr/bin/env bash
# Daily: report the skills update. Silent when all is well. memory-diff.sh is its own hourly job.
# It no longer pulls ~/dev/ticket-bay: the sandbox writes that clone's .git, so a git run there on the
# host would run its hooks and config. bug-loop fetches from inside the sandbox instead.
# The skills checkout lives in /opt, owned by skills-sync, which updates it at 07:50 Berlin
# (/etc/cron.d/skills-pull, vps/skills-sync/); this job runs at 07:55.
st=$(cat "${SKILLS_STATUS:-/var/lib/skills-sync/status}" 2>/dev/null || echo "skills update status missing")
[ "$st" = ok ] || echo "$st"
