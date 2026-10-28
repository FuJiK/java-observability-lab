# Scenario 01: 正常系と requestId

## 目的

1リクエストを `requestId` で追跡する。

## 実行

```bash
curl -i \
  -H 'Content-Type: application/json' \
  -H 'X-Request-ID: training-001' \
  -d '{"externalId":"ORDER-001","customerId":"CUSTOMER-001","amount":1200}' \
  http://localhost:8080/orders
```

## 観察ポイント

- レスポンスヘッダーの `X-Request-ID`
- Controller → Service → Hibernate SQL まで同じ requestId が付くか
- INSERT SQL と bind 値
