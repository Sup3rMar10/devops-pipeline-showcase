#!/usr/bin/env bash
# Prove the safety net works: ship a release whose health check fails, show the cluster refuses to switch over
# (old pods keep serving), then roll back and confirm the good version is back.
#   scripts/rollback_drill.sh <good-version>
set -euo pipefail
good="${1:?usage: rollback_drill.sh <good-version>}"

echo "== 1. releasing a build whose readiness probe fails (probe path /does-not-exist)"
kubectl patch deployment hello --type=json -p \
  '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/does-not-exist"}]'

if kubectl rollout status deployment/hello --timeout=45s; then
  echo "FAIL: the bad release was not caught"; exit 1
fi
echo "== 2. rollout stalled as expected; the service must still be serving the good version"
scripts/smoke.sh "$good"

echo "== 3. rolling back"
kubectl rollout undo deployment/hello
kubectl rollout status deployment/hello --timeout=90s
scripts/smoke.sh "$good"
echo "OK: bad release blocked, service stayed up, rollback restored version $good"
