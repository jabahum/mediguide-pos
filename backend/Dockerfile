FROM golang:1.25.7-alpine3.23 AS build
ARG BUILD_VERSION=development
ARG BUILD_REVISION=unknown
WORKDIR /src
RUN apk add --no-cache git ca-certificates
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags "-X mediguide/internal/buildinfo.Version=${BUILD_VERSION} -X mediguide/internal/buildinfo.Revision=${BUILD_REVISION}" \
    -o /out/api ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/migrate ./cmd/migrate

FROM build AS development-build
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/seed ./cmd/seed

FROM alpine:3.23 AS production
ARG BUILD_VERSION=development
ARG BUILD_REVISION=unknown
LABEL org.opencontainers.image.title="MediGuide Backend API" \
      org.opencontainers.image.version="${BUILD_VERSION}" \
      org.opencontainers.image.revision="${BUILD_REVISION}"
WORKDIR /app
RUN apk add --no-cache ca-certificates tzdata curl && \
    addgroup -S -g 10001 mediguide && \
    adduser -S -D -H -u 10001 -G mediguide mediguide && \
    mkdir -p /app/dashboard/samples && \
    chown -R mediguide:mediguide /app
COPY --from=build --chown=mediguide:mediguide /out/api /app/api
COPY --from=build --chown=mediguide:mediguide /out/migrate /app/migrate
COPY --chown=mediguide:mediguide migrations /app/migrations
COPY --chown=mediguide:mediguide docs /app/docs
USER 10001:10001
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=6 \
  CMD curl --fail --silent http://127.0.0.1:8080/api/readyz >/dev/null || exit 1
CMD ["/app/api"]

FROM production AS development
USER root
COPY --from=development-build --chown=mediguide:mediguide /out/seed /app/seed
USER 10001:10001
