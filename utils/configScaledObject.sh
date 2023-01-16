
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
SCALED_OBJECT_FILE="./keda/scaled_object.yaml"

QUEUE_NAME=`$YQ e ".queueName" $VALUES_FILE` 

SVC_IP=`$KUBECTL get svc -n $RABBITMQ_NAMESPACE test-cluster  -o json | $JQ -r '.spec.clusterIP'`
SVC_PORT=`$KUBECTL get svc -n $RABBITMQ_NAMESPACE test-cluster -o json |$JQ -r '.spec.ports | map(select(.appProtocol == "amqp"))[0].port'`
RABBIT_SVC_IP_PORT="$SVC_IP:$SVC_PORT"

RABBITMQ_USERNAME=`$KUBECTL get secret -n $RABBITMQ_NAMESPACE test-cluster-default-user -o jsonpath='{.data.username}' | base64 --decode`
RABBITMQ_PASSWORD=`$KUBECTL get secret -n $RABBITMQ_NAMESPACE test-cluster-default-user -o jsonpath='{.data.password}' | base64 --decode`

$YQ e ".spec.triggers[0].metadata.metricName=\"$QUEUE_NAME-metrics\"" \
$SCALED_OBJECT_FILE > "${SCALED_OBJECT_FILE}.tmp" && \
mv "${SCALED_OBJECT_FILE}.tmp" $SCALED_OBJECT_FILE

$YQ e ".spec.triggers[0].metadata.host=\"amqp://$RABBITMQ_USERNAME:$RABBITMQ_PASSWORD@$RABBIT_SVC_IP_PORT\"" \
$SCALED_OBJECT_FILE > "${SCALED_OBJECT_FILE}.tmp" && \
mv "${SCALED_OBJECT_FILE}.tmp" $SCALED_OBJECT_FILE

$YQ e ".spec.triggers[0].metadata.queueName=\"$QUEUE_NAME\"" \
$SCALED_OBJECT_FILE > "${SCALED_OBJECT_FILE}.tmp" && \
mv "${SCALED_OBJECT_FILE}.tmp" $SCALED_OBJECT_FILE






