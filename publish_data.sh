seq 50 | kafka-console-producer.sh --request-required-acks 1 \
  --broker-list localhost:9092 --topic testTopic && echo 'Produced 50 messages.'