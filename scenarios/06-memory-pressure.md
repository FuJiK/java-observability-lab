# Scenario 06: JVM メモリ圧迫

## 注意

このエンドポイントは学習用。`lab` profile でのみ有効。
本番環境へ公開しない。

## 実行

まず JVM の heap を小さくして起動する。

```bash
export MAVEN_OPTS='-Xms128m -Xmx128m'
SPRING_PROFILES_ACTIVE=lab mvn spring-boot:run
```

別ターミナルから、10MBずつ保持させる。

```bash
for i in $(seq 1 20); do
  curl -s -X POST \
    -H "X-Request-ID: memory-$i" \
    'http://localhost:8080/lab/memory/allocate?megabytes=10'
  echo
done
```

## 観察ポイント

```bash
curl http://localhost:8080/actuator/metrics/jvm.memory.used
curl http://localhost:8080/actuator/metrics/jvm.gc.pause
curl -o heapdump.hprof http://localhost:8080/actuator/heapdump
```

## 復旧

OOM前なら保持データを解放できる。

```bash
curl -X POST http://localhost:8080/lab/memory/clear
```
