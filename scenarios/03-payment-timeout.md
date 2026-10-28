# Scenario 03: 外部API Timeout

## 目的

アプリケーション自身ではなく、依存先の遅延が原因であるケースを切り分ける。

## 実行

```bash
curl -i \
  -H 'X-Request-ID: training-timeout-001' \
  'http://localhost:8080/lab/payment-timeout?delayMs=3000'
```

HTTPクライアントの read timeout は2秒、mock paymentは3秒待つため timeout する。

## 期待結果

HTTP 504。

## 調査観点

- 呼び出し開始時刻
- timeout 発生時刻
- `ResourceAccessException`
- nested exception
- mock payment側が3秒後まで処理していること

クライアントが諦めても、サーバ側処理が止まるとは限らない点も観察する。
