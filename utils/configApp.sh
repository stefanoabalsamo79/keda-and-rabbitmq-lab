
#!/bin/sh
set -e

APP=$1
ENV=$2

YQ=`which yq`
JQ=`which jq`
KUBECTL=`which kubectl`
INSTALLATION_INFO_FILE="./installation_info.yaml"
NAMESPACE=`$YQ e ".app.$APP.namespace" $INSTALLATION_INFO_FILE` 
RABBITMQ_NAMESPACE=`$YQ e ".rabbitMqNamespace" $INSTALLATION_INFO_FILE` 
VALUES_FILE="./containers/${APP}/deploy/values.yaml"
ARTIFACT_REGISTRY=`$YQ e ".repositoryInfos.$ENV.artifactRegistry" $INSTALLATION_INFO_FILE`

$YQ e ".artifactRegistry=\"$ARTIFACT_REGISTRY\"" \
$VALUES_FILE > "${VALUES_FILE}.tmp" && \
mv "${VALUES_FILE}.tmp" $VALUES_FILE

SVC_IP=`$KUBECTL get svc -n $RABBITMQ_NAMESPACE test-cluster  -o json | $JQ -r '.spec.clusterIP'`
SVC_PORT=`$KUBECTL get svc -n $RABBITMQ_NAMESPACE test-cluster -o json |$JQ -r '.spec.ports | map(select(.appProtocol == "amqp"))[0].port'`
RABBIT_SVC_IP_PORT="$SVC_IP:$SVC_PORT"

$YQ e ".rabbitSvcIpPort=\"$RABBIT_SVC_IP_PORT\"" \
$VALUES_FILE > "${VALUES_FILE}.tmp" && \
mv "${VALUES_FILE}.tmp" $VALUES_FILE

RABBITMQ_USERNAME=`$KUBECTL get secret -n $RABBITMQ_NAMESPACE test-cluster-default-user -o jsonpath='{.data.username}' | base64 --decode`
RABBITMQ_PASSWORD=`$KUBECTL get secret -n $RABBITMQ_NAMESPACE test-cluster-default-user -o jsonpath='{.data.password}' | base64 --decode`

$YQ e ".rabbitUsername=\"$RABBITMQ_USERNAME\"" \
$VALUES_FILE > "${VALUES_FILE}.tmp" && \
mv "${VALUES_FILE}.tmp" $VALUES_FILE

$YQ e ".rabbitPassword=\"$RABBITMQ_PASSWORD\"" \
$VALUES_FILE > "${VALUES_FILE}.tmp" && \
mv "${VALUES_FILE}.tmp" $VALUES_FILE







