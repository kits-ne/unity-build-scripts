#!/usr/bin/env bash

set -ex

UNITY_VERSION=2021.3.3f1
GAME_CI_VERSION=1.0.1 # https://github.com/game-ci/docker/releases
MY_USERNAME=qkrsogusl3
COMPOSE_FILE=./unity-build-scripts/docker-compose.yml
COMPOSE_ENV_FILE=./unity-build-scripts/.env
COMPOSE_ENV_FILE_SAMPLE=./unity-build-scripts/.env.sample

if [ -z "$UNITY_LICENSE" ] || [ -z "$PLATFORM" ]; then 
    echo "not found env"
    echo UNITY_LICENSE=$UNITY_LICENSE;
    echo PLATFORM=$PLATFORM;
    exit 1;
fi

if [ ! -f $COMPOSE_ENV_FILE ]; then
    #touch $COMPOSE_ENV_FILE;
    cp $COMPOSE_ENV_FILE_SAMPLE $COMPOSE_ENV_FILE
fi

# don't hesitate to remove unused components from this list
declare -a components=("$PLATFORM")

for component in "${components[@]}"
do
  export GAME_CI_UNITY_EDITOR_IMAGE=unityci/editor:ubuntu-${UNITY_VERSION}-${component}-${GAME_CI_VERSION}
  export IMAGE_TO_PUBLISH=${MY_USERNAME}/editor:ubuntu-${UNITY_VERSION}-${component}-${GAME_CI_VERSION}
  export PLATFORM=${component}

  args=("$@")

  if [[ " ${args[*]} " =~ "-rmi" ]]; then
    args="${args[@]/-rmi}";
    docker rmi $(docker images -q $IMAGE_TO_PUBLISH) || true;
  fi
  
  if [ -z $(docker images -q $IMAGE_TO_PUBLISH) ]; then
    docker-compose -f ${COMPOSE_FILE} build;
  fi
: '
  docker-compose -f ${COMPOSE_FILE} run \
      --entrypoint /bin/bash \
      --rm \
      -v $(echo $(pwd):/app) \
      -v /tmp:/tmp \
      unity
'
  docker-compose -f ${COMPOSE_FILE} run \
      --rm \
      -v $(echo $(pwd):/app) \
      -v /tmp:/tmp \
      unity $(echo ${args})
# uncomment the following to publish the built images to docker hub
#  docker push ${IMAGE_TO_PUBLISH}
done
