curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/fossas/fossa-cli/master/install-latest.sh | bash -s -- -b ~/bin
REPO_NAME=${GITHUB_REPOSITORY##*/}
~/bin/fossa analyze --project $REPO_NAME
FOSSA_TEST=`~/bin/fossa test --json --project $REPO_NAME || exit 0`
[ -z "$FOSSA_TEST" ] && FOSSA_TEST={}
JSON_PAYLOAD="{\"repo_name\": \"$REPO_NAME\", \"fossa_issues\": $FOSSA_TEST}"
echo $JSON_PAYLOAD
curl -d "$JSON_PAYLOAD" -H 'Content-Type: application/json' -H 'X-Auth-Token: $FOSSA_EVENT_RECEIVER_TOKEN' 'https://event-management-system.internal.intercom.io/fossa_event_receiver?event_type=fossa_licensing_issues'
~/bin/fossa report attribution