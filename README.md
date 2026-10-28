# Java Observability Lab

Spring Boot アプリケーションに意図的な障害を発生させ、
**Logs / HTTP / DB / JVM / Metrics** を使って原因調査するための学習用リポジトリです。

## このLabで身につけること

- `requestId` を使った1リクエストの追跡
- Java stack trace と `Caused by` の読み方
- Spring Boot の Controller / Service / Repository の責務
- PostgreSQL の制約違反の切り分け
- 外部HTTP APIの 500 と timeout の違い
- JVM heap / GC / thread の観測
- Spring Boot Actuator / Micrometer の基本
- 「現象 → 仮説 → 証拠 → 原因 → 修正」の障害調査フロー

## 技術スタック

- Java 21
- Spring Boot 4.1.2
- Spring Web
- Spring Data JPA
- PostgreSQL 17
- HikariCP
- Spring Boot Actuator
- Micrometer / Prometheus endpoint
- Docker Compose

## 構成

```text
java-observability-lab/
├── pom.xml
├── docker-compose.yml
├── Makefile
├── scenarios/
│   ├── 01-normal-request.md
│   ├── 02-duplicate-key.md
│   ├── 03-payment-timeout.md
│   ├── 04-payment-500.md
│   ├── 05-unexpected-exception.md
│   └── 06-memory-pressure.md
└── src/
    ├── main/
    │   ├── java/com/example/observability/
    │   │   ├── config/
    │   │   ├── controller/
    │   │   ├── dto/
    │   │   ├── entity/
    │   │   ├── exception/
    │   │   ├── filter/
    │   │   ├── repository/
    │   │   └── service/
    │   └── resources/application.yml
    └── test/
```

## 1. 前提

確認する。

```bash
java -version
mvn -version
docker --version
docker compose version
```

Java 21 を想定しています。

## 2. PostgreSQL 起動

```bash
docker compose up -d postgres
```

状態確認。

```bash
docker compose ps
```

## 3. Spring Boot 起動

障害訓練用エンドポイントを有効にするため `lab` profile で起動します。

```bash
SPRING_PROFILES_ACTIVE=lab mvn spring-boot:run
```

または、Make が利用可能なら次でも構いません。

```bash
make db-up
make run
```

## 4. Health Check

```bash
curl -i http://localhost:8080/actuator/health
```

期待例。

```json
{
  "status": "UP"
}
```

## 5. 正常な注文を作成

```bash
curl -i \
  -H 'Content-Type: application/json' \
  -H 'X-Request-ID: training-001' \
  -d '{
    "externalId": "ORDER-001",
    "customerId": "CUSTOMER-001",
    "amount": 1200
  }' \
  http://localhost:8080/orders
```

ログには概ね以下の形式で `requestId` が出ます。

```text
2026-10-28 18:30:01.123 INFO  [http-nio-8080-exec-1] [requestId=training-001] ... - Creating order ...
```

クライアントから `X-Request-ID` が渡されなければ、アプリケーション側でUUIDを生成します。
レスポンスにも `X-Request-ID` を返します。

## 6. 注文参照

```bash
curl -i \
  -H 'X-Request-ID: training-get-001' \
  http://localhost:8080/orders/1
```

存在しない注文を指定すると HTTP 404 になります。

```bash
curl -i \
  -H 'X-Request-ID: training-get-404' \
  http://localhost:8080/orders/999999
```

## 7. 障害シナリオ

順番に実行してください。

1. `scenarios/01-normal-request.md`
2. `scenarios/02-duplicate-key.md`
3. `scenarios/03-payment-timeout.md`
4. `scenarios/04-payment-500.md`
5. `scenarios/05-unexpected-exception.md`
6. `scenarios/06-memory-pressure.md`

## 8. Actuator

Health。

```bash
curl http://localhost:8080/actuator/health
```

利用可能な metrics。

```bash
curl http://localhost:8080/actuator/metrics
```

JVMメモリ。

```bash
curl http://localhost:8080/actuator/metrics/jvm.memory.used
```

GC pause。

```bash
curl http://localhost:8080/actuator/metrics/jvm.gc.pause
```

HTTP server requests。

```bash
curl http://localhost:8080/actuator/metrics/http.server.requests
```

Prometheus形式。

```bash
curl http://localhost:8080/actuator/prometheus
```

Thread dump。

```bash
curl http://localhost:8080/actuator/threaddump
```

Heap dump。

```bash
curl -o heapdump.hprof http://localhost:8080/actuator/heapdump
```

`heapdump` はファイルサイズが大きくなることがあります。

## 9. ログ調査の基本フロー

障害が起きたら、いきなり全ログを眺めるのではなく以下で進めます。

```text
HTTPステータス / 発生時刻
        ↓
requestId
        ↓
ERROR / WARN
        ↓
stack trace
        ↓
Caused by
        ↓
DB / HTTP依存先 / JVM / アプリコード
        ↓
仮説
        ↓
Metrics・SQL・Thread Dump等で裏取り
        ↓
根本原因
```

## 10. DB制約違反で見るポイント

同一 `externalId` を2回登録すると、2回目はHTTP 409になります。

重要なのは最上位の例外名だけを見ることではありません。

```text
DataIntegrityViolationException
    ↓
Hibernate / JDBC
    ↓
PostgreSQL exception
    ↓
duplicate key / unique constraint
```

という因果関係を辿ります。

## 11. 外部API Timeoutで見るポイント

```bash
curl -i \
  -H 'X-Request-ID: training-timeout' \
  'http://localhost:8080/lab/payment-timeout?delayMs=3000'
```

HTTPクライアントは2秒で timeout します。
mock payment は3秒待つため、呼び出し元では HTTP 504 になります。

ここでは、

```text
自アプリが遅い
```

のか、

```text
依存先が遅い
```

のかを切り分けます。

## 12. 注意事項

`/lab/**` は障害を意図的に発生させる学習用エンドポイントです。
`lab` profile でのみ有効ですが、インターネットへ公開しないでください。

Actuator の `heapdump` や `threaddump` も、本番では無認証公開すべきではありません。

## 次のPhase

v0.2では以下を追加する予定です。

- OpenTelemetry Java Agent
- traceId / spanId のログ相関
- Prometheus
- Grafana
- Tempo または Jaeger
- PostgreSQL slow query
- HikariCP connection pool 枯渇
- thread pool 枯渇
- retry storm
- Docker化した Spring Boot App

これにより、最終的に以下を横断して障害を追える構成にします。

```text
Logs + Metrics + Traces + JVM + DB + HTTP
```
