FUEGO_VERSION = 0.10.0
FUEGO_CHECKSUM = c8b81dcd7aab402e0da34e45a1500f2053ed7e24669b4fb6985f9fe136ec9579

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
		--tag $(IMAGE_NAME) .

scan: $(EXTRACTED_FILE)
	if [ ! -f gitlab.tpl ] ; then curl --output gitlab.tpl https://raw.githubusercontent.com/aquasecurity/trivy/master/contrib/gitlab.tpl;  fi

	$(TRIVY_COMMAND) trivy --clear-cache
	$(TRIVY_COMMAND) trivy --input $(EXTRACTED_FILE) --exit-code 0 --no-progress --format template --template "@gitlab.tpl" -o gl-container-scanning-report.json $(IMAGE_NAME)
	$(TRIVY_COMMAND) trivy --input $(EXTRACTED_FILE) --exit-code 1 --no-progress --ignore-unfixed --severity CRITICAL $(IMAGE_NAME)

$(EXTRACTED_FILE):
	docker save --output $(EXTRACTED_FILE) $(IMAGE_NAME)

publishDockerhub:
	docker tag $(IMAGE_NAME) $(DOCKERHUB_IMAGE)
	docker push $(DOCKERHUB_IMAGE)
	docker tag $(IMAGE_NAME) $(DOCKERHUB_IMAGE):$(TAG)
	docker push $(DOCKERHUB_IMAGE):$(TAG)

publishGitlab:
	docker tag $(IMAGE_NAME) $(GITLAB_IMAGE)
	docker push $(GITLAB_IMAGE)
	docker tag $(IMAGE_NAME) $(GITLAB_IMAGE):$(TAG)
	docker push $(GITLAB_IMAGE):$(TAG)

gitRelease:
	-git tag -d $(TAG)
	-git push origin :refs/tags/$(TAG)
	git tag $(TAG)
	git push origin $(TAG)
	git push

clean:
	$(TRIVY_COMMAND) rm -rf gitlab.tpl .cache *.tar *.json
