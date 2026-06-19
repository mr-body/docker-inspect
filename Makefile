REGISTRY = mrbody
TAG = beta.0.4

API = docker-inspect-api
UI = docker-inspect-ui

# -------------------------
# DOCKER COMPOSE
# -------------------------
up:
	docker compose up --build

down:
	docker compose down

logs:
	docker compose logs -f

# -------------------------
# API
# -------------------------
build-api:
	docker build -t $(API):latest ./docker-inspect-api

tag-api:
	docker tag $(API):latest $(REGISTRY)/$(API):$(TAG)

push-api:
	docker push $(REGISTRY)/$(API):$(TAG)

deploy-api: build-api tag-api push-api

# -------------------------
# UI
# -------------------------
build-ui:
	docker build -t $(UI):latest ./docker-inspect-ui

tag-ui:
	docker tag $(UI):latest $(REGISTRY)/$(UI):$(TAG)

push-ui:
	docker push $(REGISTRY)/$(UI):$(TAG)

deploy-ui: build-ui tag-ui push-ui

# -------------------------
# FULL DEPLOY
# -------------------------
deploy: deploy-api deploy-ui
	@echo "✅ Deploy completo finalizado: $(REGISTRY)"

# -------------------------
# CLEAN (opcional)
# -------------------------
clean:
	docker system prune -f