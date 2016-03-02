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

TMP_DOCKER_COMPOSE_DIR="/tmp/$SCRIPT_PATH"
mkdir -p $TMP_DOCKER_COMPOSE_DIR
TMP_DOCKER_COMPOSE_FILE="$TMP_DOCKER_COMPOSE_DIR/player-$USER-$$.yml"

echo $TMP_DOCKER_COMPOSE_FILE
cat "$SCRIPT_PATH/player.yml" > $TMP_DOCKER_COMPOSE_FILE
echo "    - PLAYER_OPTS=$@" >> $TMP_DOCKER_COMPOSE_FILE
echo "  command: bootstrap.sh $PWD" >> $TMP_DOCKER_COMPOSE_FILE
echo "  volumes:" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - $SCRIPT_PATH:/external" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - $PWD:$PWD" >> $TMP_DOCKER_COMPOSE_FILE 
cat $TMP_DOCKER_COMPOSE_FILE

docker-compose -f "$TMP_DOCKER_COMPOSE_FILE" run player
rm $TMP_DOCKER_COMPOSE_FILE -f
