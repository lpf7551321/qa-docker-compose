#!/bin/bash

readlink_f () {
  cd "$(dirname "$1")" > /dev/null
  filename="$(basename "$1")"
  if [ -h "$filename" ]; then
    readlink_f "$(readlink "$filename")"
  else
    echo "`pwd -P`/$filename"
  fi
}

SELF=$(readlink_f "$0")
SCRIPT_PATH=$(dirname "$SELF")

I=1

CONFIG="trunk.config"

RES_ARGS=""

while [ $I -le $# ]; do
  S=1
  eval "PEEK=\${$I}"
  case "$PEEK" in
    -config)
        I=$(expr $I + 1)
        eval "VAL=\${$I}"
        CONFIG="$VAL"
        ;;
    *)
        RES_ARGS="$RES_ARGS $PEEK"
        ;;
  esac
  I=$(expr $I + $S)
done


cd $SCRIPT_PATH/..; bin/j2.py --config $CONFIG docker-compose.yml.j2

docker-compose -f docker-compose.yml $RES_ARGS
