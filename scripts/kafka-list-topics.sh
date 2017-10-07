#!/bin/bash

# Args:
# $1 - kafka client; defaults to kafka-0 but you could set it to kafka-client, etc.

c=${1:-kafka-0}

oc rsh $c bin/kafka-topics.sh --zookeeper zookeeper:2181 --list
