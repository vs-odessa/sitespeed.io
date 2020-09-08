#!/bin/bash
set -eu

DIR=$(dirname "$0")
BROWSERTIME_RECORD=../bin/browsertimeWebPageReplay.js
BROWSERTIME=../bin/sitespeed.js

HTTP_PORT=80
HTTPS_PORT=443

CERT_FILE=../docker/webpagereplay/wpr_cert.pem
KEY_FILE=../docker/webpagereplay/wpr_key.pem
SCRIPTS=../docker/webpagereplay/deterministic.js

WPR_HTTP_PORT=8082
WPR_HTTPS_PORT=8081
DEVICE_SERIAL=${DEVICE_SERIAL:-ZY322MMFZ2}
DELAY=${DELAY:-100}

WPR_ARCHIVE=./archive.wprgo
WPR_RECORD_LOG=./wpr-record.log
WPR_REPLAY_LOG=./wpr-replay.log

# Reverse the traffic for the android device back to the computer
adb -s $DEVICE_SERIAL reverse tcp:$WPR_HTTP_PORT tcp:$WPR_HTTP_PORT
adb -s $DEVICE_SERIAL reverse tcp:$WPR_HTTPS_PORT tcp:$WPR_HTTPS_PORT

function shutdown {
    kill -2 $replay_pid
    wait $replay_pid
    kill -s SIGTERM ${PID}
    wait $PID
}

WPR_PARAMS="--http_port $WPR_HTTP_PORT --https_port $WPR_HTTPS_PORT --https_cert_file $CERT_FILE --https_key_file $KEY_FILE --inject_scripts $SCRIPTS $WPR_ARCHIVE"
WAIT=${WAIT:-5000}
REPLAY_WAIT=${REPLAY_WAIT:-3}
RECORD_WAIT=${RECORD_WAIT:-3}

declare -i RESULT=0
echo 'Start WebPageReplay Record'
./wpr record $WPR_PARAMS > $WPR_RECORD_LOG 2>&1 &
record_pid=$!
sleep $RECORD_WAIT
node $BROWSERTIME_RECORD --browsertime.firefox.preference network.dns.forceResolve:127.0.0.1 --browsertime.chrome.args host-resolver-rules="MAP *:$HTTP_PORT 127.0.0.1:$WPR_HTTP_PORT,MAP *:$HTTPS_PORT 127.0.0.1:$WPR_HTTPS_PORT,EXCLUDE localhost" --android true "$@"
RESULT+=$?

kill -2 $record_pid
RESULT+=$?
wait $record_pid
echo 'Stopped WebPageReplay record'

if [ $RESULT -eq 0 ]
    then
      echo 'Start WebPageReplay Replay'
      ./wpr replay $WPR_PARAMS > $WPR_REPLAY_LOG 2>&1 &
      replay_pid=$!
      sleep $REPLAY_WAIT
      if [ $? -eq 0 ]
        then
          node $BROWSERTIME --firefox.preference network.dns.forceResolve:127.0.0.1 --firefox.preference security.OCSP.enabled:0 --chrome.args host-resolver-rules="MAP *:$HTTP_PORT 127.0.0.1:$WPR_HTTP_PORT,MAP *:$HTTPS_PORT 127.0.0.1:$WPR_HTTPS_PORT,EXCLUDE localhost" --connectivity.engine throttle --android --browsertime.chrome.args "ignore-certificate-errors-spki-list=PhrPvGIaAMmd29hj8BCZOq096yj7uMpRNHpn5PDxI6I=" --browsertime.chrome.args "user-data-dir=/tmp/chrome" "$@" &
          PID=$!

          trap shutdown SIGTERM SIGINT
          wait $PID 
          kill -s SIGTERM $replay_pid
          wait $replay_pid
        else
          echo "Replay server didn't start correctly" >&2
          exit 1
      fi
else
  echo "Recording or accessing the URL failed, will not replay" >&2
    exit 1
fi