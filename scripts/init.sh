#!/bin/bash

modify_resolv_conf() {
  DNS=`cat /etc/hosts | grep skydns | head -n 1 | awk '{print $1}'`
  [ -z "${DNS}" ] && {
    echo "can't find skydns from /etc/hosts:"
    cat /etc/hosts
    return 1
  }
  sed -i -c "s/ skydns$/ ${DNS}/g" /etc/resolv.conf
}

announce_service() {
  IFS='.' read -a HOSTNAME_ARRAY <<< $1
  for element in ${HOSTNAME_ARRAY[@]}
  do
    REVERSE_HOSTNAME="/${element}${REVERSE_HOSTNAME}"
  done

  i=5
  until [ $i -eq 0 ]
  do
    IPADDR=`ip addr show eth0 | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
    [ -z "${IPADDR}" ] || {
       break
    }
    sleep 10
    i=`expr $i - 1`
  done

  [ $i -eq 0 ] && {
     echo "ERROR: failed to get IP of eth0"
     return 1
  }

  PTR_PATH_BASE=`echo $2 | awk -F "v2/keys/skydns" '{print $1}'`
  PTR_PATH=$PTR_PATH_BASE"v2/keys/skydns/arpa/in-addr/"`echo $IPADDR|sed 's/\./\//g'`

  IP_VALUE="{\"Host\":\"$IPADDR\"}"
  PTR_VALUE="{\"host\":\"$HOSTNAME\"}"

  echo "annouce service: $2${REVERSE_HOSTNAME} $IP_VALUE, reverse mapping: $PTR_PATH $PTR_VALUE"
  curl -XPUT $2${REVERSE_HOSTNAME} -d value=$IP_VALUE > /dev/null
  curl -XPUT $PTR_PATH -d value=$PTR_VALUE > /dev/null
}

modify_resolv_conf

[ -z "$SKYDNS_PATH" ] || announce_service `hostname` ${SKYDNS_PATH}
