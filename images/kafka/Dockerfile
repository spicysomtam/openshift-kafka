FROM openjdk:8-jre
LABEL description="kafka"

ARG INSTALL_DIR=/opt
ARG VERSION=0.11.0.0
ARG SCALA_VERSION=2.11

# Need ps (procps) for the kafka stop script.
RUN apt-get update --fix-missing && \
    apt-get install -y procps && \
    apt-get clean && \
    rm -rf /var/tmp/* /tmp/* /var/lib/apt/lists/* && \
    mirror=$(curl --stderr /dev/null https://www.apache.org/dyn/closer.cgi\?as_json\=1|sed 's/"//g'|awk '/preferred/ {print $2}') && \
    echo $mirror && \
    cd /opt && \
    wget -nv -O - ${mirror}/kafka/$VERSION/kafka_$SCALA_VERSION-$VERSION.tgz | gunzip -c -f | tar -xf - && \
    mv kafka_$SCALA_VERSION-$VERSION kafka && \
    sed -i 's/zookeeper.connect=localhost:2181/zookeeper.connect=zookeeper:2181/' kafka/config/server.properties && \
    chgrp -R 0 kafka && \
    chmod -R g+rw kafka

WORKDIR /opt/kafka

ENTRYPOINT ["./bin/kafka-server-start.sh"]

CMD ["config/server.properties"]
