.PHONY: db-up db-down run test clean

db-up:
	docker compose up -d postgres

db-down:
	docker compose down

run:
	SPRING_PROFILES_ACTIVE=lab mvn spring-boot:run

test:
	mvn test

clean:
	mvn clean
