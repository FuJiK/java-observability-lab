# Scenario 04: 外部API 500

## 目的

Timeout と「依存先がHTTPエラーを返したケース」を区別する。

## 実行

```bash
curl -i \
  -H 'X-Request-ID: training-payment-500' \
  http://localhost:8080/lab/payment-500
```

## 期待結果

- mock payment: HTTP 500
- 呼び出し元: HTTP 502

## 調査観点

`RestClientResponseException` のHTTPステータスとレスポンス本文を確認する。
