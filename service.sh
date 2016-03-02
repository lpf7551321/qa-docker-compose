#!/bin/bash

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


./j2.py --config $CONFIG docker-compose.yml.j2

docker-compose -f docker-compose.yml $RES_ARGS
