#!/bin/bash

# Alastair Munro 15 Sep 2017
# This is for zookeeper 3.5 and later that supports dynamic configuration.
# It will work with a single instance, but ideally you want to have a minimum of 3 replicas in the statefulset for a functoning zookeeper cluster.
# This works if a pod is killed; the cluster will adapt it quorum. If the leader pod is killed a new leader will be elected.
# Needless to say, killed/dieing pods will be recreated automatically via the statefulset, and then merged back into the cluster.
# You can scale the statefulset upwards dynamically and it all works perfectly (ensure you have enough pvc's). Additional zk pods are added to the cluster quorum.
#
# Update history:
# 15 Sep 2017
# zoo.cfg file changes can be done by putting them on the command line. Template has been updated to reflect this.

# Get the k8s service from the hostname
svc=$(hostname -f|cut -d. -f2)
hnamefq=$(hostname -f)
hname=$(hostname -s)
myid=$(($(echo $hname|awk -F'-' '{print $NF}')+1))
dmn=${hnamefq#${hname}.}
dyn=conf/zoo.cfg.dynamic
cfg=conf/zoo.cfg

# Ensure anything created is g+rw, since openshift uses gid 0 access. Block other access.
umask 0007

[ ! -d /tmp/zookeeper ] && mkdir -p /tmp/zookeeper

# Set myid based on hostname
echo "My zk id: $myid"

# These help debugging:
echo "My uid: $(id)"
echo "/tmp/zookeeper files/permissions:"
find /tmp/zookeeper -ls

echo $myid > /tmp/zookeeper/myid

echo "reconfigEnabled=true" >> $cfg # See https://issues.apache.org/jira/browse/ZOOKEEPER-2014

# Startup the static config with number of instances defined.
c=0
while [ $c -lt $myid ]
do
  echo "server.$(($c+1))=$(echo $hname|cut -d- -f1)-$c.$dmn:2888:3888:participant;2181" >> $dyn
  c=$(($c+1))
done

# Lets add zookeepers that are already defined. Prevents zoo-0 not being able to join zoo-1, etc.
# We use ping since dig/nslookup is not installed.
while [[ ! $(ping -c 1 -w 2 zoo-$c.$dmn 2>&1) =~ unknown\ host ]]
do
  echo "server.$(($c+1))=$(echo $hname|cut -d- -f1)-$c.$dmn:2888:3888:participant;2181" >> $dyn
  c=$(($c+1))
done

# Update the config file by putting settings on the command line
while [ "$1" != "" ]; do
  echo "Making this config change: $1"
  opt=$(echo $1|cut -d= -f1)
  val=$(echo $1|cut -d= -f2)

# If in the file, edit, otherwise append
  if grep -E -q ^$opt= $cfg
  then
    sed -i "s/$opt=.*/$opt=$val/" $cfg
  else
    echo $1 >> $cfg
  fi

  shift
done

echo "Zookeeper config installed ($cfg):"
cat $cfg
echo ""

echo "Zookeeper dynamic startup config installed ($dyn):"
cat $dyn
echo ""

exec bin/zkServer.sh start-foreground
