#!/usr/bin/env bash
# Smoke test: call the running service through a port-forward and check it reports the expected version.
#   scripts/smoke.sh <expected-version>
set -euo pipefail
expected="${1:?usage: smoke.sh <expected-version>}"
kubectl port-forward svc/hello 8080:80 >/dev/null 2>&1 &
pf=$!
trap 'kill $pf 2>/dev/null || true' EXIT
for _ in $(seq 1 20); do
  if body=$(curl -sf http://localhost:8080/version); then
    echo "service answered: $body"
    case "$body" in
      *"\"$expected\""*) echo "OK: running version matches $expected"; exit 0 ;;
      *) echo "FAIL: expected version $expected"; exit 1 ;;
    esac
  fi
  sleep 1
done
echo "FAIL: service never answered"; exit 1
