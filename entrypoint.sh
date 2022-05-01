#!/bin/bash

set -e

function post_slack {
    local value = "${1}"
    local webhook_url = 'https://hooks.slack.com/services/' + ${INPUT_SLACK_TOKEN}
    local payload="{\"text\":\"secret :: $value\"}"
    curl -X POST -H "Content-type: application/json" --data "$payload" $slack_url
}

if [ -f "${INPUT_BASELINE_FILE}" ]; then
  cp ${INPUT_BASELINE_FILE} .secrets.new
  detect-secrets scan --baseline .secrets.new $(find . -type f ! -name '.secrets.*' ! -name 'go.sum' ! -name 'go.mod' ! -path '*/.git*')
  list_secrets() { jq -r '.results | keys[] as $key | "\($key),\(.[$key] | .[])"' "$1" | sort; }
  if (diff <(list_secrets .secrets.baseline) <(list_secrets .secrets.new) | grep ">"); then
    echo ""
    echo "⚠️ Detected new secrets in the repo"
    if (${INPUT_SLACK_TOKEN}); then
      post_slack "secret found"
    fi  
    exit 1
  fi
else
  echo "No detect-secrets baseline file found!"
  exit -1
fi