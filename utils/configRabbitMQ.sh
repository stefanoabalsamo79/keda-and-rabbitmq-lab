#!/bin/sh
set -e

ENV=$1

checkEnv() {
	TARGET=$1
	TARGETS=("local")
	if [[ ! " ${TARGETS[*]} " =~ " ${TARGET} " ]]; then	echo "Target environment not correctly valued (${TARGETS[*]})";	exit 1; fi
}

checkEnv "$ENV"

YQ=`which yq`
KUBECTL=`which kubectl`
CURL=`which curl`
INSTALLATION_INFO_FILE="installation_info.yaml"
RABBITMQ_NAMESPACE=`$YQ e ".rabbitMqNamespace" $INSTALLATION_INFO_FILE`

username="$(kubectl get secret -n $RABBITMQ_NAMESPACE test-cluster-default-user -o jsonpath='{.data.username}' | base64 --decode)" && echo "username: $username"
password="$(kubectl get secret -n $RABBITMQ_NAMESPACE test-cluster-default-user -o jsonpath='{.data.password}' | base64 --decode)" && echo "password: $password"
$CURL --fail \
-u$username:$password \
localhost/api/overview

$CURL --fail \
-i -u $username:$password \
-H "content-type:application/json" \
-XPUT -d'{"type":"fanout","durable":true}' \
http://localhost/api/exchanges/%2f/my.exchange.1

$CURL --fail \
-i -u $username:$password \
-H "content-type:application/json" \
-XPUT -d'{"durable":true,"arguments":{}}' \
http://localhost/api/queues/%2f/my.queue.1

# $CURL --fail \
# -i -u $username:$password \
# -H "content-type:application/json" \
# -XPUT -d'{"durable":true,"arguments":{"x-dead-letter-exchange":"", "x-dead-letter-routing-key": "my.queue.1.dead-letter"}}' \
# http://localhost/api/queues/%2f/my.queue.1


# $CURL --fail \
# -i -u $username:$password \
# -H "content-type:application/json" \
# -XPUT -d'{"durable":true,"arguments":{}}' \
# http://localhost/api/queues/%2f/my.queue.1.dead-letter
    
# $CURL --fail \
# -i -u $username:$password \
# -H "content-type:application/json" \
# -XPOST -d'{"routing_key":"","arguments":{}}' \
# http://localhost/api/bindings/%2f/e/my.exchange/q/my.queue.1