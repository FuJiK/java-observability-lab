#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

echo "== Java =="
command -v java >/dev/null || fail "java not found. Install: brew install openjdk@21"
java -version 2>&1 | head -1

echo
echo "== Maven =="
command -v mvn >/dev/null || fail "mvn not found. Install: brew install maven"
mvn -version 2>&1 | head -1

echo
echo "== Docker =="
command -v docker >/dev/null || fail "docker not found. Install Docker Desktop for Mac."
docker compose version >/dev/null 2>&1 || fail "docker compose not available."

echo
echo "== PostgreSQL (compose) =="
docker compose up -d postgres
docker compose ps postgres

echo
echo "== Unit tests =="
mvn -q test

echo
echo "== Start app manually =="
echo "  Terminal A: SPRING_PROFILES_ACTIVE=lab mvn spring-boot:run"
echo "  Terminal B: bash scripts/smoke-test.sh"
echo
echo "Or in Cursor: Run and Debug → \"Observability Lab (lab profile)\" (after \"lab: docker postgres up\" task)."
