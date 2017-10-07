#!/bin/bash

# A Munro 12 Sep 2017
#
# UPDATE HISTORY:
# A Munro: 20 sep 2017: It could be dangerous in a prod setup to just blindly import images 
#                       and thus update against what is registry. This would cause redeploys.
#                       Thus check if the imagestream already exists before import and don't 
#                       allow import if it exists. Can override if arg $1 is set to force.
# 
# A Munro: 4 Oct 2017: Now we use the env tags rather than latest

. ./kafka.env

tag=$(echo $PROJ|awk -F'-' '{print $2}')

[ -z "$tag" ] && tag=latest
[[ $tag =~ ^(origin|dev)$ ]] && tag=latest

for i in $OS_IMAGES
do
  im=$(echo $i|cut -d: -f1)

  [ "$1" != "force" ] && {
    [ ! -z "$(oc get is $im 2>/dev/null|awk -v t=$tag '$3 == t')" ] && {
      echo "Imagestream $im:$tag is already imported. Use arg 'force' if you want reimport it; this may cause a redeployment."
      continue
    }
  }

  oc import-image $im:$tag --from=$OS_REGISTRY$OS_IMAGE_PREFIX$im:$tag --confirm
done

