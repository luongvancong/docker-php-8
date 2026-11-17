#!/usr/bin/env bash
# Dùng: scripts/smoke-test-fpm.sh <image> [expected_php_version] [expected_mongodb_version]
set -euo pipefail

IMAGE="${1:?usage: smoke-test-fpm.sh <image> [php_version] [mongodb_version]}"
EXPECTED="${2:-8.4.27}"
MONGO_EXPECTED="${3:-1.21.1}"
run() { docker run --rm "$IMAGE" "$@"; }

echo "== php -v"
run php -v | tee /dev/stderr | grep -q "PHP $EXPECTED"

echo "== php -m"
MODULES="$(run php -m)"
for ext in pdo_mysql mbstring gd zip bcmath intl exif pcntl "Zend OPcache" soap \
           mongodb redis excimer sodium curl openssl; do
  if grep -qx "$ext" <<<"$MODULES"; then echo "ok  $ext"; else echo "MISSING $ext"; exit 1; fi
done

# 9189 khai config.platform ext-mongodb chính xác -> sai patch là composer install fail.
echo "== ext-mongodb version"
run php -r 'echo phpversion("mongodb"), PHP_EOL;' | tee /dev/stderr | grep -qx "$MONGO_EXPECTED"

echo "== gd (freetype, jpeg)"
run php -r '$i = gd_info(); exit(!empty($i["FreeType Support"]) && !empty($i["JPEG Support"]) ? 0 : 1);'

echo "== tools"
run composer --version
run ssh -V
run git --version

echo "== fpm config"
run php-fpm -t

echo "== fpm listening"
CID="$(docker run -d "$IMAGE")"
trap 'docker rm -f "$CID" >/dev/null 2>&1 || true' EXIT
ok=0
for _ in $(seq 1 20); do
  if docker exec "$CID" php -r '$f=@fsockopen("127.0.0.1", 9000, $e, $s, 2); exit($f ? 0 : 1);'; then
    ok=1; break
  fi
  sleep 1
done
[ "$ok" = 1 ] || { docker logs "$CID"; echo "php-fpm not listening on 9000"; exit 1; }

echo "SMOKE TEST PASSED"
