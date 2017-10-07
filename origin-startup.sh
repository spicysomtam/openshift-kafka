#!/bin/bash
# A Munro 24 Aug 2017: Startup openshift origin, and then call script to provision all the openshift metadata
# Local openshift spin up for testing of kafka

# vars:
project=$1 # Pass as an arg. TODO: Allows different projects/namespaces for different environments.

[ -z "$project" ] && \
  project=kafka-origin # In k8s namespace, but the arg for openshift is -n!

# Main
# -------------------------------------------------------------------------------

oc cluster up && {
  oc login -u system:admin
  oc new-project $project

# Only required for the local maz; allow local maz to run as root
  oc adm policy add-scc-to-user anyuid -n $project -z default
  oc policy add-role-to-user admin developer # So we can access all projects on the gui

  ./scripts/build-images.sh || exit 1
  ./scripts/deploy-origin.sh
}
