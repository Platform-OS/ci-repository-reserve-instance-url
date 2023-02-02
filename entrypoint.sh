#!/bin/sh -l

set -eu

METHOD=$1
CI_REPO_URL=${2}/api/instances
POS_CI_REPO_ACCESS_TOKEN=$3

GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-octocat/Hello-World}
GITHUB_RUN_ID=${GITHUB_RUN_ID:-run-888}

CLIENT=${GITHUB_REPOSITORY}--${GITHUB_RUN_ID}--${GITHUB_RUN_NUMBER:-0}
CLIENT=${CLIENT/\//--}

request() {
  curl -sS  -X$1 \
    -H "Authorization: Bearer $POS_CI_REPO_ACCESS_TOKEN" \
    -H 'Content-type: application/json' ${CI_REPO_URL}/${2:-} \
    -d "{\"client\":\"$CLIENT\"}" \
    --fail-with-body
}

case $METHOD in

  release)
    request DELETE release
    ;;

  reserve)
    MPKIT_URL=$(request POST reserve)
    echo "MPKIT_URL=$MPKIT_URL" >> $GITHUB_ENV

    REPORT_PATH=$(echo $MPKIT_URL | cut -d'/' -f3)/$(date +'%Y-%m-%d-%H-%M-%S')
    echo "REPORT_PATH=$REPORT_PATH" >> $GITHUB_ENV
    ;;

  test)
    request POST test
    ;;

  all)
    request POST
    ;;
  *)
    echo $METHOD command not found: Usage: ./scripts/ci/repository all | reserve | release
esac


