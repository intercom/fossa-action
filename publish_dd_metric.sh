METRIC_NAME=$1
METRIC_VALUE=$2
HOST=$3

if [[ -z ${DATADOG_API_KEY} || -z ${METRIC_NAME} || -z ${METRIC_VALUE} || -z ${HOST} ]]; then
  echo "One or more required variables are missing: DATADOG_API_KEY, METRIC_NAME, METRIC_VALUE, HOST"
  exit 0
fi

export NOW="$(date +%s)"

curl -sS -X POST "https://api.datadoghq.com/api/v1/series" \
-H "Content-Type: text/json" \
-H "DD-API-KEY: ${DATADOG_API_KEY}" \
-d @- << EOF
{
  "series": [
    {
      "metric": "${METRIC_NAME}",
      "host": "${HOST}",
      "type": "gauge",
      "points": [
        [
          "${NOW}",
          "${METRIC_VALUE}"
        ]
      ]
    }
  ]
}
EOF