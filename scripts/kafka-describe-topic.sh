#!/bin/bash

# Args:
# $1 - kafka client; defaults to kafka-0 but you could set it to kafka-client, etc.
# $2 - topic; default test1

c=${1:-kafka-0}
t=${2:-test1}

oc rsh $c bin/kafka-topics.sh --zookeeper zookeeper:2181 --describe --topic $t
