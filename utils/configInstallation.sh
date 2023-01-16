#!/bin/sh
set -e

ENV=$1

checkEnv() {
	TARGET=$1
	TARGETS=("local")
	if [[ ! " ${TARGETS[*]} " =~ " ${TARGET} " ]]; then	echo "Target environment not correctly valued (${TARGETS[*]})";	exit 1; fi
}

pushImage() {
  IMAGE_SRC=$1
  QUALIFIED_IMAGE_URL=$2
  CLUSTER_NAME=$3
  $DOCKER pull "$IMAGE_SRC"
  $DOCKER tag "$IMAGE_SRC" "$QUALIFIED_IMAGE_URL"
  $KIND load \
  docker-image "$QUALIFIED_IMAGE_URL" \
  --name "$CLUSTER_NAME"
}

checkEnv "$ENV"

YQ=`which yq`
KUBECTL=`which kubectl`
DOCKER=`which docker`
KIND=`which kind`
INSTALLATION_INFO_FILE="installation_info.yaml"
KEDA_MANIFEST="./keda/keda-2.9.1.yaml"
RABBITMQ_OPERATOR_MANIFEST="./rabbitmq/cluster-operator.yml"

INGRESS_CONTROLLER_FILE="./infra/ingress_controller.yaml"
CLUSTER_NAME=`$YQ e ".clusterName" $INSTALLATION_INFO_FILE`
ARTIFACT_REGISTRY=`$YQ e ".repositoryInfos.$ENV.artifactRegistry" $INSTALLATION_INFO_FILE`

INGRESS_NGINX_CONTROLLER_IMAGE_SRC=`$YQ e ".images.ingress-nginx-controller.imageSrc" $INSTALLATION_INFO_FILE`
INGRESS_NGINX_CONTROLLER_IMAGE_DEST=`$YQ e ".images.ingress-nginx-controller.imageDest" $INSTALLATION_INFO_FILE`
INGRESS_NGINX_CONTROLLER_IMAGE_TAG_DEST=`$YQ e ".images.ingress-nginx-controller.imageTagDest" $INSTALLATION_INFO_FILE`
INGRESS_NGINX_CONTROLLER_QUALIFIED_IMAGE_URL="${ARTIFACT_REGISTRY}${INGRESS_NGINX_CONTROLLER_IMAGE_DEST}:${INGRESS_NGINX_CONTROLLER_IMAGE_TAG_DEST}"
pushImage "$INGRESS_NGINX_CONTROLLER_IMAGE_SRC" "$INGRESS_NGINX_CONTROLLER_QUALIFIED_IMAGE_URL" "$CLUSTER_NAME"
$YQ e -i "select(.kind == \"Deployment\" and .metadata.name == \"ingress-nginx-controller\").spec.template.spec.containers[0].image |= \"$INGRESS_NGINX_CONTROLLER_QUALIFIED_IMAGE_URL\"" $INGRESS_CONTROLLER_FILE

KUBE_WEBHOOK_CERTGEN_IMAGE_SRC=`$YQ e ".images.kube-webhook-certgen.imageSrc" $INSTALLATION_INFO_FILE`
KUBE_WEBHOOK_CERTGEN_IMAGE_DEST=`$YQ e ".images.kube-webhook-certgen.imageDest" $INSTALLATION_INFO_FILE`
KUBE_WEBHOOK_CERTGEN_IMAGE_TAG_DEST=`$YQ e ".images.kube-webhook-certgen.imageTagDest" $INSTALLATION_INFO_FILE`
KUBE_WEBHOOK_CERTGEN_QUALIFIED_IMAGE_URL="${ARTIFACT_REGISTRY}${KUBE_WEBHOOK_CERTGEN_IMAGE_DEST}:${KUBE_WEBHOOK_CERTGEN_IMAGE_TAG_DEST}"
pushImage "$KUBE_WEBHOOK_CERTGEN_IMAGE_SRC" "$KUBE_WEBHOOK_CERTGEN_QUALIFIED_IMAGE_URL" "$CLUSTER_NAME"
$YQ e -i "select(.kind == \"Job\" and .metadata.name == \"ingress-nginx-admission-create\").spec.template.spec.containers[0].image |= \"$KUBE_WEBHOOK_CERTGEN_QUALIFIED_IMAGE_URL\"" $INGRESS_CONTROLLER_FILE
$YQ e -i "select(.kind == \"Job\" and .metadata.name == \"ingress-nginx-admission-patch\").spec.template.spec.containers[0].image |= \"$KUBE_WEBHOOK_CERTGEN_QUALIFIED_IMAGE_URL\"" $INGRESS_CONTROLLER_FILE

KEDA_METRICS_APISERVER_IMAGE_SRC=`$YQ e ".images.keda-metrics-apiserver.imageSrc" $INSTALLATION_INFO_FILE`
KEDA_METRICS_APISERVER_IMAGE_DEST=`$YQ e ".images.keda-metrics-apiserver.imageDest" $INSTALLATION_INFO_FILE`
KEDA_METRICS_APISERVER_IMAGE_TAG_DEST=`$YQ e ".images.keda-metrics-apiserver.imageTagDest" $INSTALLATION_INFO_FILE`
KEDA_METRICS_APISERVER_QUALIFIED_IMAGE_URL="${ARTIFACT_REGISTRY}${KEDA_METRICS_APISERVER_IMAGE_DEST}:${KEDA_METRICS_APISERVER_IMAGE_TAG_DEST}"
pushImage "$KEDA_METRICS_APISERVER_IMAGE_SRC" "$KEDA_METRICS_APISERVER_QUALIFIED_IMAGE_URL" "$CLUSTER_NAME"
$YQ e -i "select(.kind == \"Deployment\" and .metadata.name == \"keda-metrics-apiserver\").spec.template.spec.containers[0].image |= \"$KEDA_METRICS_APISERVER_QUALIFIED_IMAGE_URL\"" $KEDA_MANIFEST

KEDA_IMAGE_SRC=`$YQ e ".images.keda-operator.imageSrc" $INSTALLATION_INFO_FILE`
KEDA_IMAGE_DEST=`$YQ e ".images.keda-operator.imageDest" $INSTALLATION_INFO_FILE`
KEDA_IMAGE_TAG_DEST=`$YQ e ".images.keda-operator.imageTagDest" $INSTALLATION_INFO_FILE`
KEDA_QUALIFIED_IMAGE_URL="${ARTIFACT_REGISTRY}${KEDA_IMAGE_DEST}:${KEDA_IMAGE_TAG_DEST}"
pushImage "$KEDA_IMAGE_SRC" "$KEDA_QUALIFIED_IMAGE_URL" "$CLUSTER_NAME"
$YQ e -i "select(.kind == \"Deployment\" and .metadata.name == \"keda-operator\").spec.template.spec.containers[0].image |= \"$KEDA_QUALIFIED_IMAGE_URL\"" $KEDA_MANIFEST

RABBITMQ_OPERATOR_IMAGE_SRC=`$YQ e ".images.rabbitmq-operator.imageSrc" $INSTALLATION_INFO_FILE`
RABBITMQ_OPERATOR_IMAGE_DEST=`$YQ e ".images.rabbitmq-operator.imageDest" $INSTALLATION_INFO_FILE`
RABBITMQ_OPERATOR_IMAGE_TAG_DEST=`$YQ e ".images.rabbitmq-operator.imageTagDest" $INSTALLATION_INFO_FILE`
RABBITMQ_OPERATOR_QUALIFIED_IMAGE_URL="${ARTIFACT_REGISTRY}${RABBITMQ_OPERATOR_IMAGE_DEST}:${RABBITMQ_OPERATOR_IMAGE_TAG_DEST}"
pushImage "$RABBITMQ_OPERATOR_IMAGE_SRC" "$RABBITMQ_OPERATOR_QUALIFIED_IMAGE_URL" "$CLUSTER_NAME"
$YQ e -i "select(.kind == \"Deployment\" and .metadata.name == \"rabbitmq-cluster-operator\").spec.template.spec.containers[0].image |= \"$RABBITMQ_OPERATOR_QUALIFIED_IMAGE_URL\"" $RABBITMQ_OPERATOR_MANIFEST

