#!/usr/bin/env bash
# Dùng: scripts/smoke-test.sh <image> [expected_php_version]
set -euo pipefail

IMAGE="${1:?usage: smoke-test.sh <image> [php_version]}"
EXPECTED="${2:-8.2.35}"
PORT="${SMOKE_PORT:-18082}"
run() { docker run --rm "$IMAGE" "$@"; }

echo "== php -v"
run php -v | tee /dev/stderr | grep -q "PHP $EXPECTED"

echo "== php -m"
MODULES="$(run php -m)"
for ext in gd pdo_mysql mysqli zip exif bcmath "Zend OPcache" mongodb sodium mbstring curl openssl; do
  if grep -qx "$ext" <<<"$MODULES"; then echo "ok  $ext"; else echo "MISSING $ext"; exit 1; fi
done

echo "== gd (freetype, jpeg)"
run php -r '$i = gd_info(); exit(!empty($i["FreeType Support"]) && !empty($i["JPEG Support"]) ? 0 : 1);'

echo "== tools"
run composer --version
run ssh -V
run git --version

echo "== apache"
CID="$(docker run -d -p "$PORT:80" "$IMAGE")"
trap 'docker rm -f "$CID" >/dev/null 2>&1 || true' EXIT
code=000
for _ in $(seq 1 20); do
  code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/" || true)"
  [ "$code" != "000" ] && break
  sleep 1
done
echo "HTTP $code"
[ "$code" != "000" ]
echo "SMOKE TEST PASSED"
