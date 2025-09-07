FUEGO_VERSION = 0.35.0
FUEGO_CHECKSUM = 24748fe9d0b1373ff97988084df14f3ea1ab64364b2ea5f7e11fffe9853131e8

IMAGE_NAME ?= fuego
DOCKERHUB_IMAGE ?= fixl/$(IMAGE_NAME)
GITHUB_IMAGE ?= ghcr.io/fixl/docker-$(IMAGE_NAME)

BUILD_DATE = $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

COMMIT_SHA ?= $(shell git rev-parse --short HEAD)
PROJECT_URL ?= $(shell git config --get remote.origin.url)
RUN_URL ?= local

TAG = $(FUEGO_VERSION)

EXTRACTED_FILE = extracted.tar
DOCKER_BUILDKIT = 1

TRIVY_COMMAND = docker compose run --rm trivy
ANYBADGE_COMMAND = docker compose run --rm anybadge

# Computed
MAJOR = $(shell echo ${FUEGO_VERSION} | awk -F. '{print $$1}')
MINOR = $(shell echo ${FUEGO_VERSION} | awk -F. '{print $$1"."$$2}')
PATCH = $(FUEGO_VERSION)

GITHUB_IMAGE_LATEST = $(GITHUB_IMAGE)
GITHUB_IMAGE_MAJOR = $(GITHUB_IMAGE):$(MAJOR)
GITHUB_IMAGE_MINOR = $(GITHUB_IMAGE):$(MINOR)
GITHUB_IMAGE_PATCH = $(GITHUB_IMAGE):$(PATCH)

DOCKERHUB_IMAGE_LATEST = $(DOCKERHUB_IMAGE)
DOCKERHUB_IMAGE_MAJOR = $(DOCKERHUB_IMAGE):$(MAJOR)
DOCKERHUB_IMAGE_MINOR = $(DOCKERHUB_IMAGE):$(MINOR)
DOCKERHUB_IMAGE_PATCH = $(DOCKERHUB_IMAGE):$(PATCH)

build:
	docker buildx build \
		--progress=plain \
		--pull \
		--load \
		--build-arg FUEGO_VERSION=$(FUEGO_VERSION) \
		--build-arg FUEGO_CHECKSUM=$(FUEGO_CHECKSUM) \
		--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
		--label "org.opencontainers.image.url=https://github.com/sgarciac/fuego" \
		--label "org.opencontainers.image.authors=@fixl" \
		--label "org.opencontainers.image.version=$(FUEGO_VERSION)" \
		--label "org.opencontainers.image.created=$(BUILD_DATE)" \
		--label "org.opencontainers.image.source=$(PROJECT_URL)" \
		--label "org.opencontainers.image.revision=$(COMMIT_SHA)" \
		--label "info.fixl.github.run-url=$(RUN_URL)" \
		--tag $(IMAGE_NAME) \
		--tag $(GITHUB_IMAGE_LATEST) \
		--tag $(GITHUB_IMAGE_MAJOR) \
		--tag $(GITHUB_IMAGE_MINOR) \
		--tag $(GITHUB_IMAGE_PATCH) \
		--tag $(DOCKERHUB_IMAGE_LATEST) \
		--tag $(DOCKERHUB_IMAGE_MAJOR) \
		--tag $(DOCKERHUB_IMAGE_MINOR) \
		--tag $(DOCKERHUB_IMAGE_PATCH) \
		.

scan: $(EXTRACTED_FILE)
	docker compose pull trivy

	$(TRIVY_COMMAND) trivy clean --scan-cache
	$(TRIVY_COMMAND) trivy image --input $(EXTRACTED_FILE) --exit-code 0 --no-progress --format sarif -o trivy-results.sarif $(IMAGE_NAME)
	$(TRIVY_COMMAND) trivy image --input $(EXTRACTED_FILE) --exit-code 1 --no-progress --ignore-unfixed --severity CRITICAL $(IMAGE_NAME)

$(EXTRACTED_FILE):
	docker save --output $(EXTRACTED_FILE) $(IMAGE_NAME)

badges:
	mkdir -p public
	$(ANYBADGE_COMMAND) docker-size $(DOCKERHUB_IMAGE_PATCH) public/size
	$(ANYBADGE_COMMAND) docker-version $(DOCKERHUB_IMAGE_PATCH) public/version

publishDockerhub:
	docker push $(DOCKERHUB_IMAGE_LATEST)
	docker push $(DOCKERHUB_IMAGE_MAJOR)
	docker push $(DOCKERHUB_IMAGE_MINOR)
	docker push $(DOCKERHUB_IMAGE_PATCH)

publishGitHub:
	docker push $(GITHUB_IMAGE_LATEST)
	docker push $(GITHUB_IMAGE_MAJOR)
	docker push $(GITHUB_IMAGE_MINOR)
	docker push $(GITHUB_IMAGE_PATCH)

gitRelease:
	-git tag -d $(TAG)
	-git push origin :refs/tags/$(TAG)
	git tag $(TAG)
	git push origin $(TAG)
	git push

clean:
	$(TRIVY_COMMAND) rm -rf public/ *.tar *.sarif
	-docker rmi $(IMAGE_NAME)
	-docker rmi $(GITHUB_IMAGE_LATEST)
	-docker rmi $(GITHUB_IMAGE_MAJOR)
	-docker rmi $(GITHUB_IMAGE_MINOR)
	-docker rmi $(GITHUB_IMAGE_PATCH)
	-docker rmi $(DOCKERHUB_IMAGE_LATEST)
	-docker rmi $(DOCKERHUB_IMAGE_MAJOR)
	-docker rmi $(DOCKERHUB_IMAGE_MINOR)
	-docker rmi $(DOCKERHUB_IMAGE_PATCH)
