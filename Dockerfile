FROM        python:3.7.12-alpine3.15
ENV         INPUT_FLAGS=".secrets.flags"
ENV         INPUT_BASELINE_FILE=".secrets.baseline"
ENV         INPUT_SLACK_TOKEN=".secrets.slack_token"
ENV         INPUT_JOB_URL=".secrets.job_url"
RUN         apk add --no-cache git less openssh jq bash diffutils curl && pip install detect-secrets==1.2.0
COPY        entrypoint.sh /entrypoint.sh
ENTRYPOINT  ["/entrypoint.sh"]
