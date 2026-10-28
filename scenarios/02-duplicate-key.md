# Scenario 02: DB UNIQUE 制約違反

## 目的

上位例外だけでなく、stack trace の `Caused by` を辿って根本原因を特定する。

## 実行

同じ `externalId` を2回登録する。

```bash
curl -i \
  -H 'Content-Type: application/json' \
  -H 'X-Request-ID: training-duplicate-1' \
  -d '{"externalId":"ORDER-DUP","customerId":"CUSTOMER-001","amount":1000}' \
  http://localhost:8080/orders

curl -i \
  -H 'Content-Type: application/json' \
  -H 'X-Request-ID: training-duplicate-2' \
  -d '{"externalId":"ORDER-DUP","customerId":"CUSTOMER-002","amount":2000}' \
  http://localhost:8080/orders
```

## 期待結果

2回目は HTTP 409。

## 調査観点

ログで以下の因果関係を追う。

```text
DataIntegrityViolationException
  -> Hibernate/JDBC
    -> PostgreSQL
      -> duplicate key value violates unique constraint
```
