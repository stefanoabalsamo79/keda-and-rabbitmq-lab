# KEDA and RabbitMQ

Tiny lab for spike purpose about [`Keda`](https://keda.sh/) and how to scale base on [`RabbitMQ`](https://www.rabbitmq.com/) metrics

---
***Prerequisites:***
* [`docker`](https://www.docker.com/)
* [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
* [`kind`](https://kind.sigs.k8s.io/)
* [`yq`](https://github.com/mikefarah/yq)
* [`jq`](https://stedolan.github.io/jq/download/)
* [`curl`](https://curl.se/)
---

## Intro
The lab is composed by:
- [`keda`](https://keda.sh/) itself
- [`producer application`](./containers/producer/) which writes messages on the `RabbitMQ` queue
- [`consumer application`](./containers/consumer/) which reads messages from the `RabbitMQ` queue

In the lab we configure a `ScaledObject` KEDA's Custom Resource in order we can scale our `consumer application` based on how many messages we have within the queue.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: consumer-app-scaled-object
spec:
  scaleTargetRef:
    kind: Deployment
    name: consumer-deployment
  pollingInterval: 5
  minReplicaCount: 1
  maxReplicaCount: 5
  triggers:
    - type: rabbitmq
      metadata:
        metricName: my.queue.1-metrics
        host: amqp://user:password@rabbit_svc_ip:rabbit_svc_port
        protocol: auto
        mode: QueueLength # QueueLength | MessageRate
        value: "200"
        activationValue: "10"
        queueName: my.queue.1
        vhostName: /
```

## Install and test
```bash
make all ENV=local
```
We can access to [`RabbitMQ UI`](http://localhost/) with the credentials we can get invoking the following make target:

```bash
make get_credentials ENV=local
```

![`image_001`](./images_and_diagrams/image_001.gif)