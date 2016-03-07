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

USE_KERBEROS=0

while [ $I -le $# ]; do
  S=1
  eval "PEEK=\${$I}"
  case "$PEEK" in
    -k)
        USE_KERBEROS=1
        ;;
    *)
        ;;
  esac
  I=$(expr $I + $S)
done


TMP_DOCKER_COMPOSE_DIR="/tmp/$SCRIPT_PATH"
mkdir -p $TMP_DOCKER_COMPOSE_DIR
TMP_DOCKER_COMPOSE_FILE="$TMP_DOCKER_COMPOSE_DIR/player-$USER-$$.yml"

echo $TMP_DOCKER_COMPOSE_FILE
cat "$SCRIPT_PATH/../player.yml" > $TMP_DOCKER_COMPOSE_FILE
echo "    - PLAYER_OPTS=$@" >> $TMP_DOCKER_COMPOSE_FILE

if [ $USE_KERBEROS -eq 1 ]; then
echo "    - KRB_ENABLE=true" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - HADOOP_SECURITY_AUTHENTICATION=kerberos" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - KRB_REALM=TDH" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - HIVE_SERVER2_AUTHENTICATION=KERBEROS" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - HIVE_SECURITY_AUTHENTICATOR_MANAGER=org.apache.hadoop.hive.ql.security.SessionStateUserAuthenticator" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - KRB_ADMIN_SERVER=kerberos" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - KERBEROS_PRINCIPAL=inceptor@TDH" >> $TMP_DOCKER_COMPOSE_FILE
else
echo "    - KRB_ENABLE=false" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - HADOOP_SECURITY_AUTHENTICATION=simple" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - HIVE_SERVER2_AUTHENTICATION=NONE" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - HIVE_SECURITY_AUTHENTICATOR_MANAGER=org.apache.hadoop.hive.ql.security.HadoopDefaultAuthenticator" >> $TMP_DOCKER_COMPOSE_FILE
fi

echo "  command: bootstrap.sh $PWD" >> $TMP_DOCKER_COMPOSE_FILE
echo "  volumes:" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - $SCRIPT_PATH/..:/external" >> $TMP_DOCKER_COMPOSE_FILE
echo "    - $PWD:$PWD" >> $TMP_DOCKER_COMPOSE_FILE 
cat $TMP_DOCKER_COMPOSE_FILE

docker-compose -f "$TMP_DOCKER_COMPOSE_FILE" run player
rm $TMP_DOCKER_COMPOSE_FILE -f
