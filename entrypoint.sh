#!/bin/bash

set -e

function post_slack {
    local webhook_url='https://hooks.slack.com/services/'${INPUT_SLACK_TOKEN}
    local payload="{\"attachments\":[{ \"title\":\"Error:\", \"color\": \"#FF0000\", \"text\":\"Secrets detected in repo: $1\" },{ \"title\":\"Link:\", \"color\": \"#FF0000\", \"text\":\"$INPUT_JOB_URL }] }"
    echo $payload
    curl -X POST -H "Content-type: application/json" --data "$payload" $webhook_url
}

if [ -f "${INPUT_BASELINE_FILE}" ]; then
  cp ${INPUT_BASELINE_FILE} .secrets.new
  detect-secrets scan ${INPUT_FLAGS} --baseline .secrets.new $(find . -type f ! -name '.secrets.*' ! -name 'go.sum' ! -name 'go.mod' ! -path '*/.git*')
  list_secrets() { jq -r '.results | keys[] as $key | "\($key),\(.[$key] | .[])"' "$1" | sort; }
  if (diff <(list_secrets .secrets.baseline) <(list_secrets .secrets.new) | grep ">"); then
    echo ""
    echo "⚠️ Detected new secrets in the repo"
    if [[ ${INPUT_SLACK_TOKEN} ]]; then
      echo "1"
      run=$GITHUB_SERVER_URL"/"$GITHUB_REPOSITORY"/actions/runs/"$GITHUB_JOB
      echo $run
      post_slack $GITHUB_REPOSITORY $run
    fi
    exit 1
  fi
else
  echo "No detect-secrets baseline file found!"
  exit -1
fi
