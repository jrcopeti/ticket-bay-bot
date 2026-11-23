# Kill switch: ticket-bay-bot

**When:** a `🚫 squid blocked` message in the ticket-bay channel, or a memory diff with something
nobody saved. Telma keeps running; she shares nothing with the bot but the host. If the host itself
looks compromised (a root login you don't know, a changed `/etc`, an unknown process), run this and
[Telma's kill switch](https://github.com/jrcopeti/telma/blob/main/vps/telma/kill-switch.md), then
rebuild the VPS (see [host.md](../host.md)).

## 1. Stop

```sh
sudo -iu ticket-bay-bot hermes gateway stop --yes                 # chats and every cron job; --yes interrupts live runs
sudo systemctl --user -M ticket-bay-bot@ disable hermes-gateway   # stays off after a reboot (linger is on)
sudo -iu ticket-bay-bot bash -c 'docker ps -aq --filter name=hermes- | xargs -r docker rm -f'
```

Leave squid running: its log is the evidence.

## 2. Cut credentials

- GitHub → Settings → Applications → Installed GitHub Apps → ticket-bay-bot → Suspend. Its 1-hour
  tokens stop working with it.
- OpenRouter → Keys: disable the bot's key.
- Discord developer portal: reset its bot token, only if a session shows it was read.

## 3. Look

```sh
sudo -iu ticket-bay-bot docker exec egress-squid-1 grep TCP_DENIED /var/log/squid/access.log
sudo -iu ticket-bay-bot hermes cron list                          # which job ran at the denial's time
sudo grep -E 'tool_executor|Turn ended' /home/ticket-bay-bot/.hermes/logs/agent.log | tail -50   # what that run called
sudo -iu ticket-bay-bot git --git-dir=/home/ticket-bay-bot/.memory-audit.git log -p --since='2 days ago'   # what the hourly memory-diff saw
```

The log names the tools; the messages and arguments are in the `messages` table of
`/home/ticket-bay-bot/.hermes/state.db` (no `sqlite3` on the VPS: use Python's). Find the email or PR the run read and what it ran before the
denied request. On GitHub, check the fork's branches, PRs and comments by `ticket-bay-bot[bot]` since the last good run:
`github.com` is on the allowlist, so a push is a way out squid doesn't block.

## 4. Back on

- Undo planted memory or skills with the restore line in memory-diff's post; it names that post's
  own snapshot, so a later run doesn't change what it restores.
- Close the email that carried the injection so the next bug-loop run doesn't claim it again.
- If the host was touched: a new App private key (delete the old one) and a new OpenRouter key.
- Unsuspend the App, then `sudo systemctl --user -M ticket-bay-bot@ enable --now hermes-gateway`
