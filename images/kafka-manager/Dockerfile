# Based on https://github.com/sheepkiller/kafka-manager-docker
FROM openjdk:8-jdk
LABEL description="kafka-manager"

# kafka manager version; see git tags at https://github.com/yahoo/kafka-manager
ARG VERSION=1.3.3.14

ENV KM_CONFIGFILE="conf/application.conf"

COPY start-kafka-manager.sh /tmp/

RUN cd /tmp && \
    git clone https://github.com/yahoo/kafka-manager && \
    cd kafka-manager && \
    git checkout $VERSION && \
    echo 'scalacOptions ++= Seq("-Xmax-classfile-name", "200")' >> build.sbt && \
    ./sbt clean dist && \
    unzip  -d /opt ./target/universal/kafka-manager-${VERSION}.zip && \
    mv /opt/kafka-manager-${VERSION} /opt/kafka-manager && \
    cd /opt/kafka-manager && \
    mv /tmp/start-kafka-manager.sh . && \
    chmod +x start-kafka-manager.sh && \
    rm -fr /tmp/* /root/.sbt /root/.ivy2 && \
    chgrp -R 0 /opt/kafka-manager && \
    chmod -R g+rw /opt/kafka-manager

WORKDIR /opt/kafka-manager

EXPOSE 9000

ENTRYPOINT ["./start-kafka-manager.sh"]
