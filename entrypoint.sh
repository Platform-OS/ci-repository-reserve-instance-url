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
  curl -s  -X$1 \
    -H "Authorization: Bearer $POS_CI_REPO_ACCESS_TOKEN" \
    -H 'Content-type: application/json' \
    -d "{\"client\":\"$CLIENT\"}" \
    --fail-with-body \
    ${CI_REPO_URL}/${2:-}
}

case $METHOD in

  release)
    echo releasing instance
    request DELETE release
    ;;

  reserve)
    set +e
    request POST reserve > .log
    RESCODE=$?
    set -e
    if [ $RESCODE != 0 ]; then
      echo "Reserve request failed. [${RESCODE}]"
      cat .log
      exit 2137
    else
      MPKIT_URL=$(cat .log)
    fi
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


