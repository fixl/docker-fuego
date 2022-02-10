FUEGO_VERSION = 0.31.1
FUEGO_CHECKSUM = 4993303bc645d3bc09a0facaffa8ad57bdb09e92d4df8e4422ad940d3847e3c5

IMAGE_NAME ?= fuego
DOCKERHUB_IMAGE ?= fixl/$(IMAGE_NAME)
GITLAB_IMAGE ?= registry.gitlab.com/fixl/docker-$(IMAGE_NAME)

BUILD_DATE = $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

CI_COMMIT_SHORT_SHA ?= $(shell git rev-parse --short HEAD)
CI_PROJECT_URL ?= $(shell git config --get remote.origin.url)
CI_PIPELINE_URL ?= local

TAG = $(FUEGO_VERSION)

EXTRACTED_FILE = extracted.tar

TRIVY_COMMAND = docker-compose run --rm trivy
ANYBADGE_COMMAND = docker-compose run --rm anybadge

# Computed
MAJOR = $(shell echo ${FUEGO_VERSION} | awk -F. '{print $$1}')
MINOR = $(shell echo ${FUEGO_VERSION} | awk -F. '{print $$1"."$$2}')
PATCH = $(FUEGO_VERSION)

GITLAB_IMAGE_LATEST = $(GITLAB_IMAGE)
GITLAB_IMAGE_MAJOR = $(GITLAB_IMAGE):$(MAJOR)
GITLAB_IMAGE_MINOR = $(GITLAB_IMAGE):$(MINOR)
GITLAB_IMAGE_PATCH = $(GITLAB_IMAGE):$(PATCH)

DOCKERHUB_IMAGE_LATEST = $(DOCKERHUB_IMAGE)
DOCKERHUB_IMAGE_MAJOR = $(DOCKERHUB_IMAGE):$(MAJOR)
DOCKERHUB_IMAGE_MINOR = $(DOCKERHUB_IMAGE):$(MINOR)
DOCKERHUB_IMAGE_PATCH = $(DOCKERHUB_IMAGE):$(PATCH)

build:
	docker build \
		--pull \
		--build-arg FUEGO_VERSION=$(FUEGO_VERSION) \
		--build-arg FUEGO_CHECKSUM=$(FUEGO_CHECKSUM) \
		--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
		--label "org.opencontainers.image.url=https://github.com/sgarciac/fuego" \
		--label "org.opencontainers.image.authors=@fixl" \
		--label "org.opencontainers.image.version=$(FUEGO_VERSION)" \
		--label "org.opencontainers.image.created=$(BUILD_DATE)" \
		--label "org.opencontainers.image.source=$(CI_PROJECT_URL)" \
		--label "org.opencontainers.image.revision=$(CI_COMMIT_SHORT_SHA)" \
		--label "info.fixl.gitlab.pipeline-url=$(CI_PIPELINE_URL)" \
		--tag $(IMAGE_NAME) \
		--tag $(GITLAB_IMAGE_LATEST) \
		--tag $(GITLAB_IMAGE_MAJOR) \
		--tag $(GITLAB_IMAGE_MINOR) \
		--tag $(GITLAB_IMAGE_PATCH) \
		--tag $(DOCKERHUB_IMAGE_LATEST) \
		--tag $(DOCKERHUB_IMAGE_MAJOR) \
		--tag $(DOCKERHUB_IMAGE_MINOR) \
		--tag $(DOCKERHUB_IMAGE_PATCH) \
		.

scan: $(EXTRACTED_FILE)
	if [ ! -f gitlab.tpl ] ; then curl --output gitlab.tpl https://raw.githubusercontent.com/aquasecurity/trivy/master/contrib/gitlab.tpl;  fi

	$(TRIVY_COMMAND) trivy image --clear-cache
	$(TRIVY_COMMAND) trivy image --input $(EXTRACTED_FILE) --exit-code 0 --no-progress --format template --template "@gitlab.tpl" -o gl-container-scanning-report.json $(IMAGE_NAME)
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

publishGitlab:
	docker push $(GITLAB_IMAGE_LATEST)
	docker push $(GITLAB_IMAGE_MAJOR)
	docker push $(GITLAB_IMAGE_MINOR)
	docker push $(GITLAB_IMAGE_PATCH)

gitRelease:
	-git tag -d $(TAG)
	-git push origin :refs/tags/$(TAG)
	git tag $(TAG)
	git push origin $(TAG)
	git push

clean:
	$(TRIVY_COMMAND) rm -rf gitlab.tpl .cache *.tar
	-docker rmi $(IMAGE_NAME)
	-docker rmi $(GITLAB_IMAGE_LATEST)
	-docker rmi $(GITLAB_IMAGE_MAJOR)
	-docker rmi $(GITLAB_IMAGE_MINOR)
	-docker rmi $(GITLAB_IMAGE_PATCH)
	-docker rmi $(DOCKERHUB_IMAGE_LATEST)
	-docker rmi $(DOCKERHUB_IMAGE_MAJOR)
	-docker rmi $(DOCKERHUB_IMAGE_MINOR)
	-docker rmi $(DOCKERHUB_IMAGE_PATCH)

cleanAll:
	$(TRIVY_COMMAND) rm -rf public
	$(MAKE) clean
