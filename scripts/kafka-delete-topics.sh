#!/bin/bash

# Args:
# $1 - kafka client; defaults to kafka-0 but you could set it to kafka-client, etc.
# $2 - topics; space delimited list; put quotes around it to keep it as a single arg

c=${1:-kafka-0}
tl=(${2:-test1})

for t in ${tl[@]}
do
# Only delete it if its there
  [ ! -z "$(oc rsh kafka-0 bin/kafka-topics.sh --zookeeper zookeeper:2181 --list --topic $t 2>/dev/null)" ] && \
    oc rsh $c bin/kafka-topics.sh --zookeeper zookeeper:2181 --topic $t --delete
done
