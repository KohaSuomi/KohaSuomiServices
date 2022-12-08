#!/bin/sh

### BEGIN INIT INFO
# Provides:          koha_suomi_services_daemon
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Hypnotoad Mojolicious Server for handling API requests
### END INIT INFO

basedir="$(dirname "$(readlink --canonicalize "$0")")"

die() { echo "$@" ; exit 1 ; }

start_services() {

    pgrep -f "\<koha_suomi_services\>" > /dev/null && die "Some background scripts already running, stop them first."
    hypnotoad $basedir/koha_suomi_services
    echo "Starting background scripts."
    perl $basedir/background.pl
    echo "Done."

}

stop_services() {

    hypnotoad $basedir/koha_suomi_services -s
    IFS='
'
    for killme in $(perl $basedir/background.pl -p); do pkill -f "$killme"; done
    unset IFS

    echo "Waiting for background scripts and hypnotoad to terminate."
    while pgrep -f '\<koha_suomi_services\>' > /dev/null; do
        sleep 1
        killcounter=$(($killcounter + 1))
        test $killcounter -eq 15 && echo "15 seconds passed, still waiting."
        test $killcounter -eq 30 && die "Failed to stop one or more of the background scripts."
    done
    echo "Done."

}

reload_services() {

    pgrep -f "\<koha_suomi_services\>" > /dev/null || die "Services don't seem to be running, start them first."
    echo "Reloading stopped background scripts."
    IFS='
'
    for reload in $(perl $basedir/background.pl -p); do
        pgrep -f "$reload" > /dev/null || sh -c "$reload &"
    done
    unset IFS
    echo "Done."

}

test "$(whoami)" != "root" && die "You need to run this as root."

case "$1" in
    start | stop | reload )
        $1_services ;;
    restart )
        stop_services
        start_services ;;
    *)
        die "Usage: $0 {start|stop|restart|reload}"
esac
