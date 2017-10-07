#!/bin/bash

. kafka.env

for i in $OS_TOPICS
do
  t=$(echo $i|cut -d: -f1)
  p=$(echo $i|cut -d: -f2)
  r=$(echo $i|cut -d: -f3)
  
  scripts/kafka-create-topics.sh "" $t $p $r
done
