#!/bin/bash

rm -f response
mkfifo response

function handle_home() {
  RESPONSE=$(cat home.html | \
    sed "s/{{$COOKIE_NAME}}/$COOKIE_VALUE/")
}

function handle_login() {
  RESPONSE=$(cat login.html | \
    sed "s/{{name}}/$INPUT_VALUE/")
}

function handle_not_found() {
  RESPONSE=$(cat 404.html)
}

function handleRequest() {
  while read line; do
    trline=`echo $line | tr -d "[\r\n]"`

    [ -z "$trline" ] && break

    echo $trline

    HEADLINE_REGEX="(.*)[[:space:]](.*)[[:space:]]HTTP.*"
    [[ $trline =~ $HEADLINE_REGEX ]] && REQUEST=$(echo $trline | sed -E "s/$HEADLINE_REGEX/\1 \2/")

    CONTENT_LENGTH_REGEX='Content-Length:[[:space:]](.*)'
    [[ "$trline" =~ $CONTENT_LENGTH_REGEX ]] && CONTENT_LENGTH=`echo $trline | sed -E "s/$CONTENT_LENGTH_REGEX/\1/"`
  done

  if [ ! -z "$CONTENT_LENGTH" ]; then
    BODY_REGEX='(.*)=(.*)'

    ## Read the remaining request body
    while read -n$CONTENT_LENGTH -t1 body; do
      echo $body

      INPUT_VALUE=$(echo $body | sed -E "s/$BODY_REGEX/\2/")
    done
  fi

  case "$REQUEST" in
    "GET /")        handle_home ;;
    "POST /login")  handle_login ;;
    *)              handle_not_found ;;
  esac

  echo -e "$RESPONSE" > response
}

PORT="3000"
echo "Listening on $PORT"

while true; do
  cat response | nc -lv 3000 | handleRequest
done
