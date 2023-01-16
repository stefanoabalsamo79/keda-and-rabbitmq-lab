#!/bin/bash
NS=$1
INGRESS=$2
until false; do
  echo "waiting for ingress [${INGRESS}]"
	external_ip=$(kubectl get -n $NS ingress/$INGRESS -ojson | jq '.status.loadBalancer.ingress[0].hostname' | tr -d '"')
	sleep 5
  if [[ $external_ip != "null" ]]; then
    break
  fi
done

