#! /bin/bash

# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This volume is assumed to exist and is shared with parent of the init
# container. It contains the zookeeper installation.
INSTALL_VOLUME="/opt"

# This volume is assumed to exist and is shared with the peer-finder
# init container. It contains on-start/change configuration scripts.

# As of April-2016 is 3.4.8 is the latest stable, but versions 3.5.0 onward
# allow dynamic reconfiguration.
VERSION="3.5.0-alpha"

for i in "$@"
do
case $i in
    -v=*|--version=*)
    VERSION="${i#*=}"
    shift
    ;;
    -i=*|--install-into=*)
    INSTALL_VOLUME="${i#*=}"
    shift
    ;;
    *)
    # unknown option
    ;;
esac
done

echo installing zookeeper-"${VERSION}" into "${INSTALL_VOLUME}"
mkdir -p "${INSTALL_VOLUME}"

# Sometimes its gzipped; sometimes its not! gunzip -f works around this...
wget -nv -O - http://apache.mirrors.pair.com/zookeeper/zookeeper-"${VERSION}"/zookeeper-"${VERSION}".tar.gz | gunzip -c -f | tar -xf - -C "${INSTALL_VOLUME}"
mv "${INSTALL_VOLUME}"/zookeeper-"${VERSION}" "${INSTALL_VOLUME}"/zookeeper
cp "${INSTALL_VOLUME}"/zookeeper/conf/zoo_sample.cfg "${INSTALL_VOLUME}"/zookeeper/conf/zoo.cfg

# TODO: Should dynamic config be tied to the version?
IFS="." read -ra RELEASE <<< "${VERSION}"
if [ $(expr "${RELEASE[1]}") -gt 4 ]; then
    echo zookeeper-"${VERSION}" supports dynamic reconfiguration, enabling it
    echo "standaloneEnabled=false" >> "${INSTALL_VOLUME}"/zookeeper/conf/zoo.cfg
    echo "dynamicConfigFile="${INSTALL_VOLUME}"/zookeeper/conf/zoo.cfg.dynamic" >> "${INSTALL_VOLUME}"/zookeeper/conf/zoo.cfg
fi

# TODO: This is a hack, netcat is convenient to have in the zookeeper container
# I want to avoid using a custom zookeeper image just for this. So copy it.
NC=$(which nc)
if [ "${NC}" != "" ]; then
    echo copying nc into "${INSTALL_VOLUME}"
    cp "${NC}" "${INSTALL_VOLUME}"
fi
