YQ:=$(shell which yq)
JQ:=$(shell which jq)
KUBECTL:=$(shell which kubectl)
DOCKER:=$(shell which docker)
HELM:=$(shell which helm)
KIND:=$(shell which kind)

INFO_FILE:="../../installation_info.yaml"
VALUES_FILE:="./deploy/values.yaml"
HELM_RELEASE_NAME:=$(shell ${YQ} e '.helmReleaseName' ${VALUES_FILE})

APP_NAME:=$(shell ${YQ} e '.name' ${VALUES_FILE})
VERSION:=$(shell ${YQ} e '.version' ${VALUES_FILE})
NAMESPACE:=$(shell ${YQ} e '.namespace' ${VALUES_FILE})
ARTIFACT_REGISTRY:=$(shell ${YQ} e '.repositoryInfos.${ENV}.artifactRegistry' ${INFO_FILE})
IMAGE_NAME_TAG:=$(APP_NAME):$(VERSION)
FULLY_QUALIFIED_IMAGE_URL:=$(ARTIFACT_REGISTRY)$(IMAGE_NAME_TAG)
CLUSTER_NAME:=$(shell ${YQ} e '.clusterName' ${INFO_FILE})

print_mk_var:
	@echo "YQ: [$(YQ)]"
	@echo "JQ: [$(JQ)]"
	@echo "KUBECTL: [$(KUBECTL)]"
	@echo "DOCKER: [$(DOCKER)]"
	@echo "HELM: [$(HELM)]"
	@echo "KIND: [$(KIND)]"
	@echo "INFO_FILE: [$(INFO_FILE)]"
	@echo "APP_NAME: [$(APP_NAME)]"
	@echo "VERSION: [$(VERSION)]"
	@echo "NAMESPACE: [$(NAMESPACE)]"
	@echo "FULLY_QUALIFIED_IMAGE_URL: [$(FULLY_QUALIFIED_IMAGE_URL)]"
	@echo "CLUSTER_NAME: [$(CLUSTER_NAME)]"

build:
	$(DOCKER) build \
	-t $(IMAGE_NAME_TAG) \
	--pull \
	--no-cache \
	-f ./src/Dockerfile \
	./src

tag: 
	$(DOCKER) tag \
	$(IMAGE_NAME_TAG) \
	$(FULLY_QUALIFIED_IMAGE_URL)

load_image: 
	$(KIND) load \
	docker-image $(FULLY_QUALIFIED_IMAGE_URL) \
	--name $(CLUSTER_NAME)

# deployment_install:
# 	$(KUBECTL) apply \
# 	-n $(NAMESPACE) \
# 	-f deploy/deployment.yaml

deployment_install:
	$(HELM) upgrade \
	--debug \
	--install \
	--namespace $(NAMESPACE) \
	-f deploy/values.yaml \
	$(HELM_RELEASE_NAME) \
	deploy

