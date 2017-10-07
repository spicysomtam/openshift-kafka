#!/bin/bash

# A Munro 18 Sep 2017: deploy all components. Is driven by kafka.env

# Subroutines
# -------------------------------------------------------------------------------

# Wait for the deployment to be fully deployed. This reliant on the readiness probe in the deployment being correct.
#
# $1 deployment
# $2 loop sleep in secs
# $3 loop number of retries

chk_controller() {
  echo Waiting for $1 to startup...
  c=0
  while [ 0 -eq 0 ]
  do
    [[ $1 =~ ^dc ]] && {
      [ ! -z "$(oc get $1|awk '!/^NAME/ {if ($3 == $4) {print "Deployed"}}')" ] && return
    }

    [[ $1 =~ ^statefulset ]] && {
      [ ! -z "$(oc get $1|awk '!/^NAME/ {if ($2 == $3) {print "Deployed"}}')" ] && return
    }
    oc get $1
    sleep $2
    ((c++))
    [ $c -eq $3 ] && {
      echo Pod creation went wrong. Investigate.
      oc get pods
      return 1
    }
  done
  return 0
}

# Main
# -------------------------------------------------------------------------------

. ./kafka.env

RUID=$OS_RUN_UID

# Get the project
PROJ=$(oc project|awk '{print $3}'|sed 's/\"//g')

[ -z "$PROJ" ] && {
  echo "Cannot determine project. Exiting..."
  exit 1
}

# Import the images as imagestreams
./scripts/import-images.sh force

int=3
for d in $OS_CONTROLLERS
do
  params=$(echo $d|awk -F':' '{print $2}')
  d=$(echo $d|cut -d':' -f1)
  ty=$(echo $d|cut -d'/' -f1)
  dep=$(echo $d|cut -d'/' -f2)

  [ ! -z "$params" ] && params="-p REPLICAS=$params"

# Add run uid
  params+=" -p RUID=$RUID"

# Set the route for the kafka manager
  [ $dep = "kafka-manager" ] && params+=" -p HOSTNAME=$OS_KM"

# No pvc versions for origin
  if [[ $dep =~ ^(zoo|dynamodb|kafka)$ ]] 
  then
     oc new-app $params -f ./templates/${dep}-no-pvcs.yml
  else
     oc new-app $params -f ./templates/${dep}.yml
  fi

  chk_controller $d $int 25|| exit 1
  int=3 # Set it back

  # Things to do after a controller is started:
  [ $dep = "zoo" ] && ./scripts/zk-set-all-participant.sh
  [ $dep = "kafka" ] && ./scripts/create-topics.sh
done

exit 0
