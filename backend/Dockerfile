FROM golang:1.25-alpine AS build
WORKDIR /src
RUN apk add --no-cache git ca-certificates
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/api ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/migrate ./cmd/migrate
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/importpb ./cmd/importpb
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/seed ./cmd/seed

FROM alpine:3.20
WORKDIR /app
RUN apk add --no-cache ca-certificates tzdata curl
COPY --from=build /out/api /app/api
COPY --from=build /out/migrate /app/migrate
COPY --from=build /out/importpb /app/importpb
COPY --from=build /out/seed /app/seed
COPY migrations /app/migrations
COPY docs /app/docs
EXPOSE 8080
CMD ["sh", "-c", "/app/migrate up && /app/importpb && /app/seed && /app/api"]
# CMD ["sh", "-c", "/app/migrate up && /app/api"]
