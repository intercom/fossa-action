set +e
curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/fossas/fossa-cli/master/install-latest.sh | bash -s -- -b ~/bin
REPO_NAME=${GITHUB_REPOSITORY##*/}

ANALYZE_START_TIME="$(date +%s)"
~/bin/fossa analyze --project $REPO_NAME
ANALYZE_EXIT_CODE=$?
ANALYZE_END_TIME="$(date +%s)"
ANALYZE_TIME="$(expr $ANALYZE_END_TIME - $ANALYZE_START_TIME)"
$GITHUB_ACTION_PATH/publish_dd_metric.sh fossa.analyze.exit_code $ANALYZE_EXIT_CODE $REPO_NAME
$GITHUB_ACTION_PATH/publish_dd_metric.sh fossa.analyze.time $ANALYZE_TIME $REPO_NAME
if [ $ANALYZE_EXIT_CODE -ne 0 ]; then exit 1; fi

TEST_START_TIME="$(date +%s)"
FOSSA_TEST=`~/bin/fossa test --json --timeout 600 --project $REPO_NAME || exit 0`
TEST_END_TIME="$(date +%s)"
TEST_TIME="$(expr $TEST_END_TIME - $TEST_START_TIME)"
$GITHUB_ACTION_PATH/publish_dd_metric.sh fossa.test.time $TEST_TIME $REPO_NAME
[ -z "$FOSSA_TEST" ] && FOSSA_TEST={}

FOSSA_EMS_PAYLOAD="{\"repo_name\": \"$REPO_NAME\", \"fossa_issues\": $FOSSA_TEST}"
N_ISSUES=`echo $FOSSA_EMS_PAYLOAD | jq -r '.fossa_issues.count'`
$GITHUB_ACTION_PATH/publish_dd_metric.sh fossa.num_licensing_issues $N_ISSUES $REPO_NAME
curl -sS -d "$FOSSA_EMS_PAYLOAD" -H 'Content-Type: application/json' -H "X-Auth-Token: $FOSSA_EVENT_RECEIVER_TOKEN" 'https://event-management-system-receivers.corporate.intercom.io/fossa_event_receiver?event_type=fossa_licensing_issues'
