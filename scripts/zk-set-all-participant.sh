#!/bin/bash

# A Munro: While all our zookeepers servers are either the leader or following,
# those following will be observers rather than participators. This means the leader
# does all the work and the followers just follow rather than participate. Thus this
# script sets any observers to be a participators.
#
# With zk 3.5.3 beta the /config area is protected with acls, thus the servers need tobe
# set as skipACL=yes.

num=$(oc get statefulset/zoo|awk '!/^NAME/ {print $3}')
p=$(oc project|awk '{print $3}'|sed 's/"//g')
s=""

c=0
while [ $c -lt $num ]
do
  [ -z "$(oc rsh zoo-0 bin/zkCli.sh config|grep -E ^server.$(($c+1)))" ] && {
    [ ! -z "$s" ] && s+=",server.$(($c+1))=zoo-$c.zk.$p.svc.cluster.local:2888:3888:participant;0.0.0.0:2181"
    [ -z "$s" ] && s="server.$(($c+1))=zoo-$c.zk.$p.svc.cluster.local:2888:3888:participant;0.0.0.0:2181"
  }
  c=$(($c+1))
done

# Do the reconfigure in one go:
[ ! -x "s" ] && { \
  echo "Adding zookeeper nodes as participants: $s"
  oc rsh zoo-0 bin/zkCli.sh <<< "reconfig -add $s" | awk '/^(Committed|server|version)/'
}
