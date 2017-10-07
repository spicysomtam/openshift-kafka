#!/bin/bash

# Args:
# $1 - kafka client; defaults to kafka-0 but you could set it to kafka-client, etc.
# $2 - topic; defaults to test1

c=${1:-kafka-0}
t=${1:-test1}

#oc rsh kafka-client bin/kafka-console-consumer.sh --zookeeper zookeeper:2181 --topic $t --from-beginning
oc rsh $c bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic $t --from-beginning
