#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"

printf '\n== health ==\n'
curl -fsS "${BASE_URL}/actuator/health"
printf '\n\n== create order ==\n'
curl -i \
  -H 'Content-Type: application/json' \
  -H 'X-Request-ID: smoke-create-001' \
  -d '{"externalId":"SMOKE-ORDER-001","customerId":"SMOKE-CUSTOMER-001","amount":1500}' \
  "${BASE_URL}/orders"

printf '\n\n== get order 1 ==\n'
curl -i \
  -H 'X-Request-ID: smoke-get-001' \
  "${BASE_URL}/orders/1"

printf '\n\n== intentional exception ==\n'
curl -i \
  -H 'X-Request-ID: smoke-exception-001' \
  "${BASE_URL}/lab/exception" || true

printf '\n\n== payment timeout ==\n'
curl -i \
  -H 'X-Request-ID: smoke-timeout-001' \
  "${BASE_URL}/lab/payment-timeout?delayMs=3000" || true

printf '\n'
