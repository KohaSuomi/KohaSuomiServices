#!/bin/bash

### BEGIN INIT INFO
# Provides:          koha_suomi_services_daemon
# Required-Start:    $syslog $remote_fs
# Required-Stop:     $syslog $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Hypnotoad Mojolicious Server for handling API requests

BASEDIR=$(dirname "$0")

if [[ $EUID -ne 0 ]]; then
    echo "You must run this script as 'root'";
    exit 1;
fi

function start {
    echo "Starting Hypnotoad"
    su -c "hypnotoad $BASEDIR/koha_suomi_services" $USER
    echo "ALL GLORY TO THE HYPNOTOAD."
}
function stop {
    su -c "hypnotoad $BASEDIR/koha_suomi_services -s" $USER
}

case "$1" in
    start)
        start
      ;;
    stop)
        stop
      ;;
    restart)
        echo "Restarting Hypnotoad"
        stop
        start
      ;;
    *)
      echo "Usage: /etc/init.d/$NAME {start|stop|restart}"
      exit 1
      ;;
esac