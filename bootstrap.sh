#!/bin/bash

[ -f /external/scripts/init.sh ] && {
  echo "here?"
  . /external/scripts/init.sh
}

source /usr/lib/transwarp/scripts/tdh-env.sh
source /usr/lib/transwarp/scripts/repeat_until_ready.sh
set -x

[ -z "${NAMENODE_STATUS}" ] ||
wait_until_ready ${NAMENODE_STATUS} "SafeMode.*COMPLETE" 5 120 || {
  echo "ERROR: failed to check status of hdfs namenode"
  exit 1
}

wait_until_ready ${INCEPTOR_SERVER}:4040/executors "Executors.*[2-9]" 5 120 || {
  echo "ERROR: failed to check status of inceptor"
  exit 1
}

if [ $KRB_ENABLE == true ]; then
  HIVE_PRINCEPLE=hive/${HOSTNAME}@${KRB_REALM}
  HDFS_PRINCEPLE=hdfs/${HOSTNAME}@${KRB_REALM}
  HBASE_PRINCEPLE=hbase/${HOSTNAME}@${KRB_REALM}
  YARN_PRINCEPLE=yarn/${HOSTNAME}@${KRB_REALM}
  #HIVE_KEYTAB=/etc/keytabs/hive.keytab
  #HBASE_KEYTAB=/etc/keytabs/hbase.keytab
  #HDFS_KEYTAB=/etc/keytabs/hdfs.keytab
  #YARN_KEYTAB=/etc/keytabs/yarn.keytab
  HIVE_KEYTAB=/etc/inceptorsql1/hive.keytab
  HBASE_KEYTAB=/etc/hyperbase1/hbase.keytab
  HDFS_KEYTAB=/etc/hdfs1/hdfs.keytab
  YARN_KEYTAB=/etc/yarn1/yarn.keytab
  [ -d /etc/keytabs ] || mkdir -p /etc/keytabs
  [ -d /etc/inceptorsql1 ] || mkdir -p /etc/inceptorsql1
  [ -d /etc/hyperbase1 ] || mkdir -p /etc/hyperbase1
  [ -d /etc/yarn1 ] || mkdir -p /etc/yarn1
  [ -d /etc/hdfs1 ] || mkdir -p /etc/hdfs1
  rm -f /etc/keytabs/*.keytab
  rm -f /etc/inceptorsql1/*.keytab
  rm -f /etc/hyperbase1/*.keytab
  rm -f /etc/yarn1/*.keytab
  rm -f /etc/hdfs1/*.keytab
  kerberos-client-install.sh -r $KRB_REALM -s $KRB_ADMIN_SERVER
  add_kerberos_conf $HBASE_PRINCEPLE $HIVE_KEYTAB
  add_kerberos_conf $HIVE_PRINCEPLE $HIVE_KEYTAB
  chown hive $HIVE_KEYTAB
  add_kerberos_conf $HBASE_PRINCEPLE $HBASE_KEYTAB
  chown hbase $HBASE_KEYTAB
  add_kerberos_conf $HDFS_PRINCEPLE $HDFS_KEYTAB
  chown hdfs $HDFS_KEYTAB
  add_kerberos_conf $YARN_PRINCEPLE $YARN_KEYTAB
  chown yarn $YARN_KEYTAB
  chmod 400 /etc/keytabs/*.keytab
  chmod 444 /etc/inceptorsql1/*.keytab
  chmod 444 /etc/hyperbase1/*.keytab
  chmod 444 /etc/yarn1/*.keytab
  chmod 444 /etc/hdfs1/*.keytab
  #sudo -u hive kinit -p $HIVE_PRINCEPLE -kt $HIVE_KEYTAB
  sudo -u hbase kinit -p $HBASE_PRINCEPLE -kt $HBASE_KEYTAB
  #sudo -u hdfs kinit -p $HDFS_PRINCEPLE -kt $HDFS_KEYTAB
  #sudo -u yarn kinit -p $YARN_PRINCEPLE -kt $YARN_KEYTAB
fi

install -d -m 777 /tmp/yarn

tmp_file=$(mktemp)
echo -e "desc 'hbase:acl'\nexit" > $tmp_file
chown hbase $tmp_file
# Execute hbase shell $tmp_file until its output contains "DESCRIPTION"
repeat_until_ready "sudo -u hbase timeout -s SIGKILL 30 hbase shell $tmp_file" DESCRIPTION 5 120 || {
  echo "ERROR: hbase:acl table doesn't exists"
  exit 1
}

tmp_file=$(mktemp)
echo -e "grant 'hive', 'RWXCA'\nexit" > $tmp_file
chown hbase $tmp_file
# Execute hbase shell $tmp_file until its output contains "0 row"
repeat_until_ready "sudo -u hbase timeout -s SIGKILL 30 hbase shell $tmp_file" "0 row" 5 120 || {
  echo "ERROR: failed granting hbase access to hive"
  exit 1
}

HIVE_SERVER=${HIVE_SERVER:-inceptor}

cd $1
java -cp /external/player-1.0-all.jar io.transwarp.qa.player.SuiteRunner \
      ${PLAYER_OPTS}

[ -z "${DEBUG}" ] || {
  echo "Waiting for debug before exit"
  while true
  do
    sleep 10
  done
}

echo "$0 sucessfully run"

