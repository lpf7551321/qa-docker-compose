FROM 172.16.1.41:5000/jenkins/test_player

ADD bootstrap_rt.sh /usr/lib/transwarp/scripts/bootstrap.sh

RUN chmod +x /usr/lib/transwarp/scripts/bootstrap.sh
