# Designed for k8s/openshift
FROM openjdk:8-jre

LABEL description="zookeeper image based on the installer gcr.io/google_containers/zookeeper-install:0.1"

ARG VERSION=3.5.3-beta

COPY install.sh /
COPY zk-start.sh /

RUN apt-get update --fix-missing && \
    apt-get install -y procps && \
    apt-get clean && \
    rm -rf /var/tmp/* /tmp/* /var/lib/apt/lists/* && \
    /install.sh --version=$VERSION --install-into=/opt && \
    cd /opt/ && \
    mv /zk-start.sh zookeeper/ && \
    chgrp -R 0 zookeeper /tmp && \
    chmod -R g+rw zookeeper /tmp && \
    chmod a+x zookeeper/zk-start.sh && \
    rm -f /install.sh

WORKDIR /opt/zookeeper

ENTRYPOINT ["./zk-start.sh"]
