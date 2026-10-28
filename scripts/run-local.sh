#!/usr/bin/env bash
set -euo pipefail

docker compose up -d postgres
SPRING_PROFILES_ACTIVE=lab mvn spring-boot:run
