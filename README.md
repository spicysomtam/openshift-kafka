# Introduction

Thanks to debianmaster/openshift-kafka as the starting point of this. My changes have deviated quite considerably from that. Specfically the dynamic zookeeper configuration and an automated deployment via kafka.env.

Its assumed you have installed Openshift Origin (tested with v3.6.0), docker (17.05.0-ce; CE/EE and non CE/EE versions), etc. Developed on Ubuntu 16.04 LTS (debian).

This script automates the startup. Take a look at the script before you run it:

```sh

./origin-startup.sh
```

We have develped an openshift container platform (ocp) version of this, which also works on openshift online. This origin setup works perfectly on ocp and online; one of the benefits of openshift is that you can develop on origin and move to ocp or online with no changes. For ocp/online use the persistent volume claim (pvc) templates to map to persistent volumes. Its outside the scope of this to tell you how to do all that. But you want your zookeeper and kafka data to persist between pod restarts?

# Automated deployment?

Openshift is based on kubernetes 1.6. Why use it? Well it has security unlike kubernetes, so you can restrict who can access what projects, it has security context constraints that tighten up security when pods are deployed, it has lots more features than kubernetes, eg deployment config image change triggers and image streams which work differently to kubernetes.

Some things are still missing. Dependancies between applications. Eg we need to have zookeeper up and configured before starting kafka. Some form of config management; how do we configure all these applications above the template configurations and deploy them? I did not find the answer to these so I cobbled something together. Thus a bunch of scripts and kafka.env environment file that has all the settings for a configuration. If you have anything better, or have the answers to this, get in contact and let me know!

# Zookeeper

A 3 pod statefulset cluster is created for zookeeper. It uses zookeeper v3.5.x (and later) that supports dynamic configuration. 3.5 is currently in beta, but we expect a full stable release soon.

It will work as as a single instance, but you should have a minimum of 3 replicas for a working zookeeper cluster. This works if a pod is killed; the cluster will adapt it quorum. If the leader pod is killed a new leader will be elected. Killed/dieing pods will be recreated automatically via the statefulset, and then merged back into the cluster. You can scale the statefulset upwards dynamically and it all works perfectly (ensure you have enough persistent volumes if using them). Additional zk pods are added to the cluster and everything in zookeeper is replicated.

You can test the scaling by increasing the replicas from 3 to 5:

```
oc scale --replicas=5 statefulset/zoo
oc get statefulsets # See how its progressing
oc get pods # Check for any crash loop/errors/restarts
```
Then tail the pod logging greping for LEAD (you will see the pods following and the leader). The new pods will be zoo-3/4. Tail the logging on the new pod.

```
$ for i in 0 1 2 3 4; do oc logs zoo-$i|awk '/(LEADING|FOLLOWING)/'|tail -1; done
2017-09-16 07:04:59,463 [myid:1] - INFO  [QuorumPeer[myid=1](plain=/0.0.0.0:2181)(secure=disabled):Leader@414] - LEADING - LEADER ELECTION TOOK - 9 MS
2017-09-16 07:05:19,876 [myid:2] - INFO  [QuorumPeer[myid=2](plain=/0.0.0.0:2181)(secure=disabled):Follower@68] - FOLLOWING - LEADER ELECTION TOOK - 8 MS
2017-09-16 07:05:39,504 [myid:3] - INFO  [QuorumPeer[myid=3](plain=/0.0.0.0:2181)(secure=disabled):Follower@68] - FOLLOWING - LEADER ELECTION TOOK - 7 MS
2017-09-16 07:07:23,116 [myid:4] - INFO  [QuorumPeer[myid=4](plain=/0.0.0.0:2181)(secure=disabled):Follower@68] - FOLLOWING - LEADER ELECTION TOOK - 8 MS
2017-09-16 07:07:45,724 [myid:5] - INFO  [QuorumPeer[myid=5](plain=/0.0.0.0:2181)(secure=disabled):Follower@68] - FOLLOWING - LEADER ELECTION TOOK - 10 MS

$ ./scripts/zk-set-all-participant.sh
Adding zookeeper nodes as participants: server.4=zoo-3.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181,server.5=zoo-4.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
Committed new configuration:
server.1=zoo-0.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.2=zoo-1.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.3=zoo-2.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.4=zoo-3.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.5=zoo-4.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181

$ oc rsh zoo-1 grep dyn conf/zoo.cfg
dynamicConfigFile=/opt/zookeeper/conf/zoo.cfg.dynamic.1e00000000

$ oc rsh zoo-0 grep dyn conf/zoo.cfg
dynamicConfigFile=/opt/zookeeper/conf/zoo.cfg.dynamic.1e00000000

$ oc rsh zoo-1 cat /opt/zookeeper/conf/zoo.cfg.dynamic.1e00000000
server.1=zoo-0.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.2=zoo-1.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.3=zoo-2.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.4=zoo-3.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.5=zoo-4.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181

$ oc rsh zoo-0 cat /opt/zookeeper/conf/zoo.cfg.dynamic.1e00000000
server.1=zoo-0.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.2=zoo-1.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.3=zoo-2.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.4=zoo-3.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
server.5=zoo-4.zk.kafka-origin.svc.cluster.local:2888:3888:participant;0.0.0.0:2181
```

Testing replication. You can create something on a zookeeper, and then ensure its replicated to all the zookeeper pods (including any scaled up pods). Do an ls of /, then create something, and ensure its replicated. Do the create on a non LEADER pod:
```
$ oc rsh zoo-0 bin/zkCli.sh -cmd ls /
.
.
[admin, brokers, cluster, config, consumers, controller, controller_epoch, isr_change_notification, kafka-manager, zookeeper]

$ oc rsh zoo-0 bin/zkCli.sh -cmd create /foo
Created /foo

$ oc rsh zoo-0 bin/zkCli.sh -cmd ls /
[admin, brokers, cluster, config, consumers, controller, controller_epoch, foo, isr_change_notification, kafka-manager, zookeeper]

$ oc rsh zoo-3 bin/zkCli.sh -cmd ls /
[admin, brokers, cluster, config, consumers, controller, controller_epoch, foo, isr_change_notification, kafka-manager, zookeeper]
```

# Kafka

Kafka is also implemented as a 3 node cluster setup. Since kafka stores its config on zookeeper, we need a robust zookeeper setup. Other than that, there isn't much to say about kafka other than it just works. Confluent have a nice book on kafka that is currently free for download. Take a look at that if you are new to kafka and want to learn more.

# Testing kafka

We want to test kafka works. We already created two topics (test1/test2; check kafka.env). So we spin up a consumer and a producer. If we enter messages in the producer, we should see them turn up at the consumer.

Open two terminal windows. In one, run:
```
$ ./scripts/kafka-consumer.sh
```

In the other, run the following. When its running, type stuff into topic test1; they should appear in the consume above:
```
$ ./scripts/kafka-producer.sh
a
c
d
```

We can describe topic test1:
```
$ $ ./scripts/kafka-describe-topic.sh
Topic:test1	PartitionCount:5	ReplicationFactor:3	Configs:
	Topic: test1	Partition: 0	Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
	Topic: test1	Partition: 1	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: test1	Partition: 2	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: test1	Partition: 3	Leader: 0	Replicas: 0,2,1	Isr: 0,2,1
	Topic: test1	Partition: 4	Leader: 1	Replicas: 1,0,2	Isr: 1,0,2
```

List all topics:

```
$ ./scripts/kafka-list-topics.sh
__consumer_offsets
test1
test2
```

# Cleanup

Just shutdown openshift origin, that clears everything out:

```sh

oc cluster down
```

# Accessing the project via the Openshift web gui

I have added admin access to the developer user, so it can see all projects. The startup script would have advised on the gui url; something like this. Thus login as developer at the url, and select the right project:

```
The server is accessible via web console at:
    https://127.0.0.1:8443

You are logged in as:
    User:     developer
    Password: <any value>
```
# Kafka Manager

I have included a yahoo kafka manager within the configuration. This connects to zookeeper:2181.

You can connect to it using your favourite web browser to http://km.local. You will need to add this host to your local hosts file, and it should resolve to the IP address on your primary network interface (if using dhcp it does change, and you will need to update it accordingly). km.local is implemented as an Openshift route.

Once you login you will need to add a cluster. Call it kafka, connect to zookeeper:2181 and select kafka version 0.11.0.0.
