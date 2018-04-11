#!/bin/sh
set -e

export PULL_REQUEST=${PULL_REQUEST:-true}
export BRANCH=${BRANCH:-master}
export TAG=${TAG:-latest}
export DOCKER_ORG=${DOCKER_ORG:-strimzici}
export DOCKER_REGISTRY=${DOCKER_REGISTRY:-docker.io}
export DOCKER_TAG=$COMMIT

make docker_build

echo "Login into Docker Hub ..."
docker login -u $DOCKER_USER -p $DOCKER_PASS

DOCKER_TAG=$BRANCH make docker_tag

DOCKER_TAG=$COMMIT make docker_tag

DOCKER_TAG=$COMMIT make docker_push

echo "Running systemtests"
./systemtest/scripts/run_tests.sh ${SYSTEMTEST_ARGS}

# If that worked we can push to the real docker org
if [ "$PULL_REQUEST" != "false" ] ; then
    echo "Building Pull Request - nothing to push"
elif [ "$TAG" = "latest" ] && [ "$BRANCH" != "master" ]; then
    echo "Not in master branch and not in release tag - nothing to push"
else
    export DOCKER_ORG=strimzi
    export DOCKER_TAG=$TAG
    echo "Pushing to docker org $DOCKER_ORG"
    make docker_push
    make docu_pushtowebsite
fi
