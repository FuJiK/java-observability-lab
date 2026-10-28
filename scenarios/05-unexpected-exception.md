# Scenario 05: 予期しない例外

## 実行

```bash
curl -i \
  -H 'X-Request-ID: training-exception-001' \
  http://localhost:8080/lab/exception
```

## 期待結果

HTTP 500。

## 調査観点

- stack trace の最初の自作コード行
- `GlobalExceptionHandler` は原因ではなく、例外を捕捉しているだけであること
- 例外発生箇所と例外処理箇所を区別する
