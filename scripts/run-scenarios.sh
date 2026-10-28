#!/usr/bin/env bash
# Runs observability lab scenarios 01–05 against a running app and writes a test report.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_URL="${BASE_URL:-http://localhost:8080}"
REPORT_DIR="${REPORT_DIR:-${ROOT}/target}"
RESET_DB="${RESET_DB:-false}"
RUN_ID="${RUN_ID:-$(date +%Y%m%d-%H%M%S)}"

mkdir -p "${REPORT_DIR}"

pass=0
fail=0
results=()

record() {
  local id="$1"
  local name="$2"
  local expected="$3"
  local actual="$4"
  local detail="${5:-}"
  local status="PASS"
  if [[ "${actual}" != "${expected}" ]]; then
    status="FAIL"
    ((fail++)) || true
  else
    ((pass++)) || true
  fi
  results+=("${id}|${name}|${expected}|${actual}|${status}|${detail}")
}

http_code() {
  curl -s -o /dev/null -w "%{http_code}" "$@"
}

http_code_time() {
  curl -s -o /dev/null -w "%{http_code} %{time_total}" "$@"
}

if [[ "${RESET_DB}" == "true" ]] && command -v docker >/dev/null 2>&1; then
  if docker compose -f "${ROOT}/docker-compose.yml" ps postgres 2>/dev/null | grep -q running; then
    docker compose -f "${ROOT}/docker-compose.yml" exec -T postgres \
      psql -U observability -d observability -c "TRUNCATE orders RESTART IDENTITY;" >/dev/null
  fi
fi

health="$(http_code "${BASE_URL}/actuator/health")"
record "health" "Actuator health" "200" "${health}" "${BASE_URL}/actuator/health"

suffix="${RUN_ID//-/}"
ext01="ORDER-01-${suffix}"
ext_dup="ORDER-DUP-${suffix}"

code="$(http_code \
  -H 'Content-Type: application/json' \
  -H 'X-Request-ID: training-001' \
  -d "{\"externalId\":\"${ext01}\",\"customerId\":\"CUSTOMER-001\",\"amount\":1200}" \
  "${BASE_URL}/orders")"
record "01" "Scenario 01 normal create" "201" "${code}" "externalId=${ext01}"

code="$(http_code \
  -H 'Content-Type: application/json' \
  -H 'X-Request-ID: training-duplicate-1' \
  -d "{\"externalId\":\"${ext_dup}\",\"customerId\":\"CUSTOMER-001\",\"amount\":1000}" \
  "${BASE_URL}/orders")"
record "02a" "Scenario 02 duplicate first" "201" "${code}" "externalId=${ext_dup}"

code="$(http_code \
  -H 'Content-Type: application/json' \
  -H 'X-Request-ID: training-duplicate-2' \
  -d "{\"externalId\":\"${ext_dup}\",\"customerId\":\"CUSTOMER-002\",\"amount\":2000}" \
  "${BASE_URL}/orders")"
record "02b" "Scenario 02 duplicate second" "409" "${code}" "unique constraint"

read -r code _time <<< "$(http_code_time \
  -H 'X-Request-ID: training-timeout-001' \
  "${BASE_URL}/lab/payment-timeout?delayMs=3000")"
record "03" "Scenario 03 payment timeout" "504" "${code}" "time=${_time}s (expect ~2s)"

code="$(http_code \
  -H 'X-Request-ID: training-payment-500' \
  "${BASE_URL}/lab/payment-500")"
record "04" "Scenario 04 payment 500" "502" "${code}" ""

code="$(http_code \
  -H 'X-Request-ID: training-exception-001' \
  "${BASE_URL}/lab/exception")"
record "05" "Scenario 05 intentional exception" "500" "${code}" ""

MD="${REPORT_DIR}/lab-scenario-results.md"
JSON="${REPORT_DIR}/lab-scenario-results.json"
JUNIT="${REPORT_DIR}/lab-scenario-results.xml"

{
  echo "# Lab scenario test results"
  echo
  echo "- **Run ID:** ${RUN_ID}"
  echo "- **Base URL:** ${BASE_URL}"
  echo "- **Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ") (UTC)"
  echo
  echo "| ID | Scenario | Expected | Actual | Result | Notes |"
  echo "|----|----------|----------|--------|--------|-------|"
  for row in "${results[@]}"; do
    IFS='|' read -r id name expected actual status detail <<< "${row}"
    echo "| ${id} | ${name} | ${expected} | ${actual} | **${status}** | ${detail} |"
  done
  echo
  echo "**Summary:** ${pass} passed, ${fail} failed"
} > "${MD}"

{
  echo "{"
  echo "  \"runId\": \"${RUN_ID}\","
  echo "  \"baseUrl\": \"${BASE_URL}\","
  echo "  \"passed\": ${pass},"
  echo "  \"failed\": ${fail},"
  echo "  \"cases\": ["
  first=true
  for row in "${results[@]}"; do
    IFS='|' read -r id name expected actual status detail <<< "${row}"
    if [[ "${first}" == "true" ]]; then
      first=false
    else
      echo ","
    fi
    printf '    {"id":"%s","name":"%s","expectedHttp":%s,"actualHttp":%s,"status":"%s","detail":"%s"}' \
      "${id}" "${name}" "${expected}" "${actual}" "${status}" "${detail}"
  done
  echo
  echo "  ]"
  echo "}"
} > "${JSON}"

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo "<testsuite name=\"lab-scenarios\" tests=\"$((pass + fail))\" failures=\"${fail}\" errors=\"0\">"
  for row in "${results[@]}"; do
    IFS='|' read -r id name expected actual status detail <<< "${row}"
    if [[ "${status}" == "PASS" ]]; then
      echo "  <testcase classname=\"scenarios\" name=\"${id} ${name}\"/>"
    else
      echo "  <testcase classname=\"scenarios\" name=\"${id} ${name}\">"
      echo "    <failure message=\"expected HTTP ${expected}, got ${actual}\">${detail}</failure>"
      echo "  </testcase>"
    fi
  done
  echo "</testsuite>"
} > "${JUNIT}"

echo "Report written:"
echo "  ${MD}"
echo "  ${JSON}"
echo "  ${JUNIT}"
echo "Summary: ${pass} passed, ${fail} failed"

if [[ "${fail}" -gt 0 ]]; then
  exit 1
fi
