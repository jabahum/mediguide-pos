BACKEND_DIR := backend
AI_WORKER_DIR := ai-worker
COMPOSE_FILE := infra/docker-compose.yml
DEV_COMPOSE_FILE := infra/docker-compose.dev.yml
DEV_ENV_FILE := infra/development.env
PRODUCTION_ENV_FILE ?= infra/production.env
DOCKER_COMPOSE := docker compose --env-file $(DEV_ENV_FILE) -f $(COMPOSE_FILE) -f $(DEV_COMPOSE_FILE)
PRODUCTION_COMPOSE := docker compose --env-file $(PRODUCTION_ENV_FILE) -f $(COMPOSE_FILE)
PYTHON ?= python3
AI_REQUIREMENTS_FILE := $(AI_WORKER_DIR)/requirements.txt
AI_REQUIREMENTS_STAMP := $(AI_WORKER_DIR)/.requirements.sha256

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf "%s\n" \
		"Available targets:" \
		"  up               Build and start the full development stack" \
		"  down             Stop the development stack and preserve data" \
		"  reset            Stop development and remove its volumes" \
		"  build            Build the development stack" \
		"  ps               Show development stack status" \
		"  logs             Tail development stack logs" \
		"  guidelines-logs  Tail the integrated guidelines service" \
		"  config           Render the merged development configuration" \
		"  prod-up          Pull, migrate, and start production with health waiting" \
		"  prod-migrate     Apply migrations with the configured production API image" \
		"  prod-down        Stop the production stack and preserve data" \
		"  prod-build       Build production images" \
		"  prod-pull        Pull production images" \
		"  prod-ps          Show production stack status" \
		"  prod-logs        Tail production stack logs" \
		"  prod-config      Render the production configuration" \
		"  test             Run backend and ai-worker tests" \
		"  backend-test     Run backend Go tests" \
		"  backend-build    Build backend binaries" \
		"  backend-run      Run backend API locally" \
		"  backend-worker   Run backend Go worker locally" \
		"  swagger          Generate backend Swagger JSON/YAML docs" \
		"  contracts        Regenerate Go, TypeScript, and Dart API contracts" \
		"  contracts-check  Verify committed API contracts have no drift" \
		"  release-prepare  Synchronize all versions from RELEASE_TAG" \
		"  release-patch    Calculate and prepare the next patch release" \
		"  release-minor    Calculate and prepare the next minor release" \
		"  release-major    Calculate and prepare the next major release" \
		"  release-check    Validate RELEASE_TAG metadata, Git state, and Compose" \
		"  migrate-up       Apply backend migrations" \
		"  migrate-down     Roll back backend migrations" \
		"  migrate-status   Show backend migration status" \
		"  seed             Seed backend data" \
		"  importpb         Import PocketBase SQLite data into backend Postgres" \
		"  ai-test          Run ai-worker tests" \
		"  ai-api           Run ai-worker FastAPI locally" \
		"  ai-worker        Run ai-worker loop locally"

.PHONY: up
up:
	$(DOCKER_COMPOSE) up -d --build

.PHONY: down
down:
	$(DOCKER_COMPOSE) down --remove-orphans

.PHONY: reset
reset:
	$(DOCKER_COMPOSE) down --volumes --remove-orphans

.PHONY: build
build:
	$(DOCKER_COMPOSE) build

.PHONY: ps
ps:
	$(DOCKER_COMPOSE) ps

.PHONY: logs
logs:
	$(DOCKER_COMPOSE) logs -f

.PHONY: config
config:
	$(DOCKER_COMPOSE) config

.PHONY: guidelines-logs
guidelines-logs:
	$(DOCKER_COMPOSE) logs -f guidelines

.PHONY: prod-up
prod-up: production-env-check
	$(PRODUCTION_COMPOSE) pull
	$(PRODUCTION_COMPOSE) run --rm api /app/migrate up
	$(PRODUCTION_COMPOSE) up --no-build -d --wait --wait-timeout 600

.PHONY: prod-migrate
prod-migrate: production-env-check
	$(PRODUCTION_COMPOSE) run --rm api /app/migrate up

.PHONY: prod-down
prod-down: production-env-check
	$(PRODUCTION_COMPOSE) down --remove-orphans

.PHONY: prod-build
prod-build: production-env-check
	$(PRODUCTION_COMPOSE) build

.PHONY: prod-pull
prod-pull: production-env-check
	$(PRODUCTION_COMPOSE) pull

.PHONY: prod-ps
prod-ps: production-env-check
	$(PRODUCTION_COMPOSE) ps

.PHONY: prod-logs
prod-logs: production-env-check
	$(PRODUCTION_COMPOSE) logs -f

.PHONY: prod-config
prod-config: production-env-check
	$(PRODUCTION_COMPOSE) config

.PHONY: production-env-check
production-env-check:
	@test -f "$(PRODUCTION_ENV_FILE)" || \
		(printf "%s\n" \
			"Missing $(PRODUCTION_ENV_FILE)." \
			"Copy infra/production.env.example and replace every placeholder." && \
		 exit 1)

.PHONY: test
test: backend-test ai-test

.PHONY: backend-test
backend-test:
	$(MAKE) -C $(BACKEND_DIR) test

.PHONY: backend-build
backend-build:
	$(MAKE) -C $(BACKEND_DIR) build

.PHONY: backend-run
backend-run:
	$(MAKE) -C $(BACKEND_DIR) run

.PHONY: backend-worker
backend-worker:
	$(MAKE) -C $(BACKEND_DIR) worker

.PHONY: swagger
swagger:
	$(MAKE) -C $(BACKEND_DIR) swagger

.PHONY: contracts
contracts:
	bash scripts/generate-contracts.sh

.PHONY: contracts-check
contracts-check:
	bash scripts/check-generated-contracts.sh

RELEASE_TAG ?=
MOBILE_BUILD_NUMBER ?=

.PHONY: release-prepare
release-prepare:
	node scripts/prepare-release.js "$(RELEASE_TAG)" $(if $(MOBILE_BUILD_NUMBER),--build-number "$(MOBILE_BUILD_NUMBER)",)

.PHONY: release-patch release-minor release-major
release-patch:
	node scripts/prepare-release.js patch $(if $(MOBILE_BUILD_NUMBER),--build-number "$(MOBILE_BUILD_NUMBER)",)

release-minor:
	node scripts/prepare-release.js minor $(if $(MOBILE_BUILD_NUMBER),--build-number "$(MOBILE_BUILD_NUMBER)",)

release-major:
	node scripts/prepare-release.js major $(if $(MOBILE_BUILD_NUMBER),--build-number "$(MOBILE_BUILD_NUMBER)",)

.PHONY: release-check
release-check:
	bash scripts/check-release-readiness.sh "$(RELEASE_TAG)"

.PHONY: migrate-up
migrate-up:
	$(MAKE) -C $(BACKEND_DIR) migrate-up

.PHONY: migrate-down
migrate-down:
	$(MAKE) -C $(BACKEND_DIR) migrate-down

.PHONY: migrate-status
migrate-status:
	$(MAKE) -C $(BACKEND_DIR) migrate-status

.PHONY: seed
seed:
	$(MAKE) -C $(BACKEND_DIR) seed

.PHONY: importpb
importpb:
	$(MAKE) -C $(BACKEND_DIR) importpb

.PHONY: ai-test
ai-test: ai-deps
	cd $(AI_WORKER_DIR) && $(PYTHON) -m pytest

.PHONY: ai-deps
ai-deps:
	@REQ_HASH=`$(PYTHON) - <<'PY'\nimport hashlib\nfrom pathlib import Path\nprint(hashlib.sha256(Path('$(AI_REQUIREMENTS_FILE)').read_bytes()).hexdigest())\nPY`; \
	STORED_HASH=""; \
	if [ -f "$(AI_REQUIREMENTS_STAMP)" ]; then STORED_HASH=`cat "$(AI_REQUIREMENTS_STAMP)"`; fi; \
	if [ "$$REQ_HASH" != "$$STORED_HASH" ]; then \
		echo "Installing ai-worker requirements"; \
		cd $(AI_WORKER_DIR) && $(PYTHON) -m pip install -r requirements.txt; \
		printf "%s" "$$REQ_HASH" > "$(AI_REQUIREMENTS_STAMP)"; \
	else \
		echo "ai-worker requirements unchanged"; \
	fi

.PHONY: ai-api
ai-api: ai-deps
	cd $(AI_WORKER_DIR) && uvicorn app.main:app --reload --host 0.0.0.0 --port 8090

.PHONY: ai-worker
ai-worker: ai-deps
	cd $(AI_WORKER_DIR) && $(PYTHON) -m app.worker

.PHONY: run-cfdp-ios-simulator
run-cfdp-ios-simulator:
	cd user_app && \
	flutter run --dart-define=MEDIGUIDE_API_BASE_URL=https://mediguide.health.go.ug

ANDROID_DEVICE ?= emulator-5554
ANDROID_API_BASE_URL ?= http://localhost:8080

.PHONY: run-cfdp-android
run-cfdp-android:
	cd user_app && \
	flutter run \
		-d $(ANDROID_DEVICE) \
		--dart-define=MEDIGUIDE_API_BASE_URL=$(ANDROID_API_BASE_URL)
