YQ:=$(shell which yq)
JQ:=$(shell which jq)
KUBECTL:=$(shell which kubectl)
DOCKER:=$(shell which docker)
KIND:=$(shell which kind)

INFO_FILE:="./installation_info.yaml"
DEFAULT_CLUSTER_NAME:=$(shell ${YQ} e '.defaultClusterName' ${INFO_FILE})
CLUSTER_NAME:=$(shell ${YQ} e '.clusterName' ${INFO_FILE})
KEDA_NAMESPACE:=$(shell ${YQ} e '.kedaNamespace' ${INFO_FILE})
RABBITMQ_NAMESPACE:=$(shell ${YQ} e '.rabbitMqNamespace' ${INFO_FILE})

HAS_YQ:=$(shell which yq > /dev/null 2> /dev/null && echo true || echo false)
HAS_JQ:=$(shell which jq > /dev/null 2> /dev/null && echo true || echo false)
HAS_KUBECTL:=$(shell which kubectl > /dev/null 2> /dev/null && echo true || echo false)
HAS_DOCKER:=$(shell which docker > /dev/null 2> /dev/null && echo true || echo false)
HAS_KIND:=$(shell which kind > /dev/null 2> /dev/null && echo true || echo false)

check_prerequisites:
ifeq ($(HAS_YQ),false) 
	$(info yq not installed!)
	@exit 1
endif
ifeq ($(HAS_JQ),false) 
	$(info jq not installed!)
	@exit 1
endif
ifeq ($(HAS_KUBECTL),false) 
	$(info kubectl not installed!)
	@exit 1
endif
ifeq ($(HAS_DOCKER),false) 
	$(info docker not installed!)
	@exit 1
endif
ifeq ($(HAS_KIND),false) 
	$(info kind not installed!)
	@exit 1
endif

params-guard-%:
	@if [ "${${*}}" = "" ]; then \
			echo "[$*] not set"; \
			exit 1; \
	fi

check_compulsory_params: params-guard-ENV

name: check_compulsory_params check_prerequisites
	@echo $(APP_NAME)

version: check_compulsory_params check_prerequisites
	@echo $(VERSION)

print_mk_var: check_compulsory_params check_prerequisites
	@echo "YQ: [$(YQ)]"
	@echo "JQ: [$(JQ)]"
	@echo "KUBECTL: [$(KUBECTL)]"
	@echo "DOCKER: [$(DOCKER)]"
	@echo "INFO_FILE: [$(INFO_FILE)]"
	@echo "DEFAULT_CLUSTER_NAME: [$(DEFAULT_CLUSTER_NAME)]"
	@echo "CLUSTER_NAME: [$(CLUSTER_NAME)]"
	@echo "KEDA_NAMESPACE: [$(KEDA_NAMESPACE)]"
	@echo "RABBITMQ_NAMESPACE: [$(RABBITMQ_NAMESPACE)]"
	@echo "ARTIFACT_REGISTRY: [$(ARTIFACT_REGISTRY)]"

cluster_start: check_prerequisites
	$(KIND) create cluster

create_cluster: check_prerequisites
	$(KIND) create \
	cluster --config=infra/cluster.yaml \
	--name $(CLUSTER_NAME)

set_context_cluster: check_prerequisites
	$(KUBECTL) config set-context $(CLUSTER_NAME)

cluster_info: check_prerequisites
	$(KUBECTL) cluster-info --context kind-$(CLUSTER_NAME)

cluster_delete: check_prerequisites
	$(KIND) delete cluster --name $(CLUSTER_NAME)
	$(KIND) delete cluster --name $(DEFAULT_CLUSTER_NAME)

config_installation: check_compulsory_params check_prerequisites
	./utils/configInstallation.sh $(ENV)

ingress_controller_install: check_compulsory_params check_prerequisites
	$(KUBECTL) apply -f infra/ingress_controller.yaml
	@sleep 30
  
wait_for_ingress_controller: check_compulsory_params check_prerequisites
	$(KUBECTL) wait \
	-n ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# keda install
keda_install: check_compulsory_params check_prerequisites
	$(KUBECTL) apply \
	-f ./keda/keda-2.9.1.yaml

wait_for_keda_operator_deploy: check_compulsory_params check_prerequisites
	$(KUBECTL) wait \
	deployment \
	-n $(KEDA_NAMESPACE) \
	keda-operator \
	--for condition=Available=True \
	--timeout=300s

config_consumer_scaled_object: check_compulsory_params check_prerequisites
	./utils/configScaledObject.sh "consumer" $(ENV)

consumer_scaled_object_install: check_compulsory_params check_prerequisites
	$(KUBECTL) apply \
	-n $(KEDA_NAMESPACE) \
	-f ./keda/scaled_object.yaml
	
# keda install

# keda uninstall
keda_uninstall: check_compulsory_params check_prerequisites
	$(KUBECTL) delete \
	--ignore-not-found \
	-f keda/keda-2.9.1yaml
# keda uninstall

# rabbitmq install
rabbitmq_install: check_compulsory_params check_prerequisites
	$(KUBECTL) apply \
	-f ./rabbitmq/cluster-operator.yml

rabbitmq_cluster_install: check_compulsory_params check_prerequisites
	$(KUBECTL) apply \
	-n $(RABBITMQ_NAMESPACE) \
	-f ./rabbitmq/cluster.yaml
	$(KUBECTL) apply \
	-n $(RABBITMQ_NAMESPACE) \
	-f ./rabbitmq/ingress.yaml

wait_for_rabbitmq_deploy: check_compulsory_params check_prerequisites
	$(KUBECTL) wait \
	-n $(RABBITMQ_NAMESPACE) \
	--for=condition=ready pod \
  --selector=app.kubernetes.io/part-of=rabbitmq \
	--timeout=300s

wait_for_rabbitmq_ingress: check_compulsory_params check_prerequisites
	./utils/waitForIngressReady.sh $(RABBITMQ_NAMESPACE) "rabbitmq-ingress"
	@sleep 40

config_rabbitmq: check_compulsory_params check_prerequisites
	./utils/configRabbitMQ.sh $(ENV)

get_rabbitmq_user: check_compulsory_params check_prerequisites
	@$(eval RABBIT_USER=`$(KUBECTL) get secret -n $(RABBITMQ_NAMESPACE) test-cluster-default-user -o jsonpath='{.data.username}' | base64 --decode`)
	@echo "RABBIT_USER: $(RABBIT_USER)"

get_rabbitmq_password: check_compulsory_params check_prerequisites
	@$(eval RABBIT_PASSWORD=`$(KUBECTL) get secret -n $(RABBITMQ_NAMESPACE) test-cluster-default-user -o jsonpath='{.data.password}' | base64 --decode`)
	@echo "RABBIT_PASSWORD: $(RABBIT_PASSWORD)"

get_credentials: check_compulsory_params check_prerequisites
	@echo "In case you wish to login RabbitMQ console here its creandentials: "
	$(MAKE) get_rabbitmq_user get_rabbitmq_password

# rabbitmq install

# rabbitmq uninstall
rabbitmq_uninstall: check_compulsory_params check_prerequisites
	$(KUBECTL) delete \
	--ignore-not-found \
	-f ./rabbitmq/cluster-operator.yml
# rabbitmq uninstall

# apps install
config_producer: check_compulsory_params check_prerequisites
	./utils/configApp.sh "producer" $(ENV)

producer_service_build_tag_push_image_apply:  check_compulsory_params check_prerequisites
	$(MAKE) -C ./containers/producer \
	build ENV=$(ENV) \
	tag ENV=$(ENV) \
	load_image ENV=$(ENV) \
	deployment_install ENV=$(ENV) \

wait_for_producer_service:  check_compulsory_params check_prerequisites
	$(KUBECTL) wait --namespace $(KEDA_NAMESPACE) \
  --for=condition=ready pod \
  --selector=app=producer \
  --timeout=90s

config_consumer: check_compulsory_params check_prerequisites
	./utils/configApp.sh "consumer" $(ENV)

consumer_service_build_tag_push_image_apply:  check_compulsory_params check_prerequisites
	$(MAKE) -C ./containers/consumer \
	build ENV=$(ENV) \
	tag ENV=$(ENV) \
	load_image ENV=$(ENV) \
	deployment_install ENV=$(ENV) \

wait_for_consumer_service:  check_compulsory_params check_prerequisites
	$(KUBECTL) wait --namespace $(KEDA_NAMESPACE) \
  --for=condition=ready pod \
  --selector=app=consumer \
  --timeout=90s
# apps install

all: 
	$(MAKE) \
	print_mk_var \
	cluster_start \
	create_cluster \
	set_context_cluster \
	cluster_info \
	config_installation \
	keda_install \
	wait_for_keda_operator_deploy \
	ingress_controller_install \
	wait_for_ingress_controller \
	rabbitmq_install \
	wait_for_rabbitmq_deploy \
	rabbitmq_cluster_install \
	wait_for_rabbitmq_deploy \
	wait_for_rabbitmq_ingress \
	config_rabbitmq \
	config_consumer \
	consumer_service_build_tag_push_image_apply \
	wait_for_consumer_service \
	config_producer \
	producer_service_build_tag_push_image_apply \
	wait_for_producer_service \
	config_consumer_scaled_object \
	consumer_scaled_object_install \
	get_credentials \

clean_up: cluster_delete

