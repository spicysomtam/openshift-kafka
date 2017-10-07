#!/bin/bash

# Args:
# $1 - kafka client; defaults to kafka-0 but you could set it to kafka-client, etc.
# $2 - topic; default test1

c=${1:-kafka-0}
t=${1:-test1}

p=$(oc project|awk '{print $3}'|sed 's/"//g')

# Need to use the lb, not a broker list. 
oc rsh $c bin/kafka-console-producer.sh --broker-list kafka.$p.svc.cluster.local:9092 --topic $t
