set +e
curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/fossas/fossa-cli/master/install-latest.sh | bash -s -- -b ~/bin
REPO_NAME=${GITHUB_REPOSITORY##*/}
~/bin/fossa analyze --project $REPO_NAME
ANALYZE_EXIT_CODE=$?
${{ github.action_path }}/publish_dd_metric.sh fossa.analyze.exit_code $ANALYZE_EXIT_CODE $REPO_NAME
if [ $ANALYZE_EXIT_CODE -ne 0 ]; then
    exit 1
fi
FOSSA_TEST=`~/bin/fossa test --json --project $REPO_NAME || exit 0`
echo "fossa test exit code: $?"
[ -z "$FOSSA_TEST" ] && FOSSA_TEST={}
FOSSA_EMS_PAYLOAD="{\"repo_name\": \"$REPO_NAME\", \"fossa_issues\": $FOSSA_TEST}"
echo $FOSSA_EMS_PAYLOAD
N_ISSUES=`echo $FOSSA_EMS_PAYLOAD | jq -r '.fossa_issues.count'`
${{ github.action_path }}/publish_dd_metric.sh fossa.num_licensing_issues $N_ISSUES $REPO_NAME
curl -d "$FOSSA_EMS_PAYLOAD" -H 'Content-Type: application/json' -H 'X-Auth-Token: $FOSSA_EVENT_RECEIVER_TOKEN' 'https://event-management-system.internal.intercom.io/fossa_event_receiver?event_type=fossa_licensing_issues'