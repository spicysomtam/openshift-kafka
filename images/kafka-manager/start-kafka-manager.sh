#!/bin/bash

if [[ "$KM_USERNAME" != '' && "$KM_PASSWORD" != '' ]]
then
    sed -i.bak '/^basicAuthentication/d' conf/application.conf
    echo 'basicAuthentication.enabled=true' >> conf/application.conf
    echo "basicAuthentication.username=${KM_USERNAME}" >> conf/application.conf
    echo "basicAuthentication.password=${KM_PASSWORD}" >> conf/application.conf
    echo 'basicAuthentication.realm="Kafka-Manager"' >> conf/application.conf
fi

exec ./bin/kafka-manager -Dconfig.file=${KM_CONFIGFILE} "${KM_ARGS}" "${@}"
