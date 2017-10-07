#!/bin/bash

# Subroutines
# -------------------------------------------------------------------------------

# $1 image
# $2 version
# $3 major version
# $4 build dir
image_chk_build() {
  # check for image; build it if its missing
  echo "Checking for docker image $1:$2."

  [ -z "$(docker images|awk -v i=$1 -v v=$2 '$1 == i && $2 == v')" ] && {
    echo "Building docker image $1:$2."
    (cd $4; docker build -t $1:$2 --build-arg VERSION=$2 --build-arg GIT_COMMIT=$GIT_COMMIT .) || {
      echo "Image build failed! Investigate and fix."
      exit 1
    }
    # Only tag to the git_commit if a new image built.
    echo "Adding docker tag $OS_REGISTRY$1:$GIT_COMMIT."
    docker tag $1:$2 $OS_REGISTRY$1:$GIT_COMMIT
  }

# Check the tagging
  for t in $1:$3 $OS_REGISTRY$1:$3
  do
    [ -z "$(docker images $t|awk '!/^REPOSITORY/')" ] && { \
      echo "Adding docker tag $t."
      docker tag $1:$2 $t
    }
  done
}

# Main
# -------------------------------------------------------------------------------

. ./kafka.env

for i in $OS_IMAGES
do
  im=$(echo $i|cut -d: -f1)
  ver=$(echo $i|cut -d: -f2)
  maj=$(echo $i|cut -d: -f3)
  image_chk_build $OS_IMAGE_PREFIX$im $ver $maj images/$im
done

exit 0
