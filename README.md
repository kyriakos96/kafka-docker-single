# Basic Docker Deployment of Apache Kafka
This Repository explains how to set up Apache Kafka Single Node 
on localhost for development purposes.

Most of the following have been inspired from [Confluent.](https://docs.confluent.io/5.0.0/installation/docker/docs/installation/single-node-client.html)

## 1. Create a Docker Network

Create the Docker network that is used to run the Confluent containers

**Important:** A Docker network is required to enable DNS resolution across your containers. The default Docker network does not have DNS enabled.

```sh
docker network create kafka-net
```

## 2. Start the Confluent Platform Components

### Start ZooKeeper
a. Start ZooKeeper and keep this service running.
```sh
docker run -d \
  --net=kafka-net \
  --name=zookeeper \
  -p 2181:2181 \
  -e ZOOKEEPER_CLIENT_PORT=2181 \
  confluentinc/cp-zookeeper:5.0.0
```
This command instructs Docker to launch an instance of the confluentinc/cp-zookeeper:5.0.0 container and name it zookeeper. Also, the Docker network confluent and the required ZooKeeper parameter ZOOKEEPER_CLIENT_PORT are specified. For a full list of the available configuration options and more details on passing environment variables into Docker containers, see the [configuration reference docs](https://docs.confluent.io/5.0.0/installation/docker/docs/config-reference.html#config-reference).

**b.** **Optional:** Check the Docker logs to confirm that the container has booted up successfully and started the ZooKeeper service.
```sh
docker logs zookeeper
```
With this command, you're referencing the container name that you want to see the logs for. To list all containers (running or failed), you can always run docker ps -a. This is especially useful when running in detached mode.

When you output the logs for ZooKeeper, you should see the following message at the end of the log output:

```sh
[2019-07-19 09:44:54,706] INFO binding to port 0.0.0.0/0.0.0.0:2181 (org.apache.zookeeper.server.NIOServerCnxnFactory)
```

**Note** that the message shows the ZooKeeper service listening at the port you passed in as ZOOKEEPER_CLIENT_PORT above.

If the service is not running, the log messages should provide details to help you identify the problem. A common error is:

Insufficient resources. In rare occasions, you may see memory allocation or other low-level failures at startup. This will only happen if you dramatically overload the capacity of your Docker host.

### Start Kafka
**a.** Start Kafka with this command.

```sh
docker run -d \
  --net=kafka-net \
  --name=kafka \
  -p 9092:9092 \
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  confluentinc/cp-kafka:5.0.0

```

The `KAFKA_ADVERTISED_LISTENERS` variable is set to `localhost:9092`. This will make Kafka accessible to other containers by advertising it's location on the Docker network. The same ZooKeeper port is specified here as the previous container.

The `KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR` is set to **1** for a single-node cluster. If you have three or more nodes, you do not need to change this from the default.
**b.** Optional: Check the logs to see the broker has booted up successfully:
```sh
docker logs kafka
```

### Create a Topic and Produce Data
**a.** Create a topic. You'll name it testTopic and keep things simple by just giving it one partition and only one replica
```sh
kafka-topics.sh --create \
  --topic testTopic \
  --partitions 1 \
  --replication-factor 1 \
  --if-not-exists \
  --zookeeper localhost:2181
```

To verify that the topic was successfully created:
```sh
kafka-topics.sh --describe --topic testTopic --zookeeper localhost:2181
```

**b.** Publish data to the topic
Run the following bash script:

```sh
bash -c "seq 50 | kafka-console-producer.sh \
  --request-required-acks 1 \
  --broker-list localhost:9092 \
  --topic testTopic && echo 'Produced 50 messages.'"
```

Read back the message using the built-in Console consumer
```sh
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic testTopic --from-beginning --max-messages 50
```