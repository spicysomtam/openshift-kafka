#!/bin/bash

# Args:
# $1 - kafka client; defaults to kafka-0 but you could set it to kafka-client, etc.
# $2 - topics; space delimited list; put quotes around it to keep it as a single arg
# $3 - Number of partitions; default 5
# $4 - Number of topic replicas; default 3

c=${1:-kafka-0}
tl=(${2:-test1})
p=${3:-5}
r=${4:-3}

for t in ${tl[@]}
do
# Only create it if its not there
  [ -z "$(oc rsh kafka-0 bin/kafka-topics.sh --zookeeper zookeeper:2181 --list --topic $t 2>/dev/null)" ] && \
    oc rsh $c bin/kafka-topics.sh --zookeeper zookeeper:2181 --topic $t --create --partitions $p --replication-factor $r
done
