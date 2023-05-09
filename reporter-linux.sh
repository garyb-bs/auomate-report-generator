# !/bin/sh
path=$1;

if [ -z "$path" ]; then
  echo "[ERROR] Output directory not passed. Please pass the first argument as output directory";
  exit 22;
fi;

if [ -z "$BROWSERSTACK_BUILD_NAME" ]; then
  echo "[ERROR] The following environment variable 'BROWSERSTACK_BUILD_NAME' must be set to generate reports";
  exit 22;
fi;

if [ ! -d $path ]; then
  echo "[WARNING] '$path' does not exists. Creating...";
  mkdir -p $path;
  if [ ! $? -eq 0 ]; then
    echo "[ERROR] Cannot create directory at '$path'"
    exit 1;
  fi
  echo "[INFO] '$path' created";
fi

cd $path;

jqpath=$(which jq)
jq_found_status=$?
if [ ! $jq_found_status -eq 0 ]; then 
  echo "[WARNING] jq not found in path. Downloading jq...";
  curl -s -L "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" > jq;
  chmod +x jq;
  jqpath=$(echo $PWD/jq);
fi;

curl -s -L "https://github.com/BrowserStackCE/automate-report-generator/releases/download/v0.1/template.html" > template.html

echo "[INFO] USERNAME - $BROWSERSTACK_USERNAME\tACCESS KEY - $BROWSERSTACK_ACCESS_KEY";
echo "[INFO] Downloading sessions for Build Name - $BROWSERSTACK_BUILD_NAME";

build=$(curl -s -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" https://api.browserstack.com/automate/builds.json?limit=50 | $jqpath -cr --arg BROWSERSTACK_BUILD_NAME "$BROWSERSTACK_BUILD_NAME" '.[] | .automation_build | select(.name == $BROWSERSTACK_BUILD_NAME) | @base64' );

buildId=$(echo $build | base64 -d | $jqpath -r '.hashed_id');
if [ -z $buildId ]; then
  echo "[ERROR] No build with name ('$BROWSERSTACK_BUILD_NAME') exists"
  exit 1;
fi
echo "[INFO] Found Build ID: $buildId"

sessions=$(curl -s -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" https://api.browserstack.com/automate/builds/$buildId/sessions.json?limit=100 | $jqpath -cr '[.[] .automation_session | @base64]');

sed s/@build/"$(echo $build)"/ template.html > template_build.html;
sed s!@session!"$(echo $sessions)"! template_build.html > index.html;

rm template.html template_build.html;

echo "[INFO] HTML report created for build: $BROWSERSTACK_BUILD_NAME...."
echo "[INFO] Downloading artifacts for the each session!"

for session in $(echo $sessions | $jqpath -cr '.[]'); do
  session_json=$(echo $session | base64 -d);
  # echo $session_json;
  hashed_id=$(echo $session_json | $jqpath -cr '.hashed_id');
  textLogsURL=$(echo $session_json | $jqpath -cr '.logs');
  consoleLogsUrl=$(echo $session_json | $jqpath -cr '.browser_console_logs_url');
  networkLogsUrl=$(echo $session_json | $jqpath -cr '.har_logs_url');
  seleniumLogsUrl=$(echo $session_json | $jqpath -cr '.selenium_logs_url');
  mkdir $hashed_id;
  curl -s -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" "$textLogsURL" > "$hashed_id"/text_logs.txt;
  curl -s "$consoleLogsUrl" > "$hashed_id"/console_logs.txt;
  curl -s "$networkLogsUrl" > "$hashed_id"/network_logs.txt;
  curl -s "$seleniumLogsUrl" > "$hashed_id"/selenium_logs.txt;
  echo "[TRACE] Loaded data for session ID: $hashed_id";
done;

echo "[INFO] Done generating reports at $PWD"

if [ ! $jq_found_status -eq 0 ]; then
  echo "[TRACE] Cleaning jq from system..."
  rm $jqpath;
fi;
