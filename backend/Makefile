-include .env
export

.PHONY: run build test tidy migrate-up migrate-down migrate-status seed importpb docker-up docker-down swagger proto

run:
	go run ./cmd/api

worker:
	go run ./cmd/worker

build:
	go build -o bin/api ./cmd/api
	go build -o bin/worker ./cmd/worker

test:
	go test ./...

tidy:
	go mod tidy

migrate-up:
	go run ./cmd/migrate up

migrate-down:
	go run ./cmd/migrate down

migrate-status:
	go run ./cmd/migrate status

seed:
	go run ./cmd/seed

importpb:
	go run ./cmd/importpb

swagger:
	go run github.com/swaggo/swag/cmd/swag@v1.16.6 init -g main.go -d cmd/api,internal/handlers,internal/httpx,internal/models,internal/services -o docs --outputTypes go,json,yaml --generatedTime=false --parseInternal

proto:
	sh ../scripts/generate_proto.sh

docker-up:
	docker compose up --build

docker-down:
	docker compose down -v
