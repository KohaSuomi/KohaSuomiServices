#!/bin/bash

BASEDIR="$(dirname "$(readlink --canonicalize "$0")")"

if [[ $EUID -ne 0 ]]; then
    echo "You must run this script as 'root'";
    exit 1;
fi

function printresults {
  su -c "perl $BASEDIR/background.pl -p" $USER
}

if test -n "$(printresults)"; then
  IFS=$'\n' read -r -d '' -a array <<< "$(printresults)"
  for dep in "${array[@]}"
  do
    echo "$dep";
    if ps aux | grep "$dep$" ; then
        echo "Process running"
        
    else
        echo "Process not running";
        su -c "$dep > /dev/null 2>&1 &" $USER
    fi
  done  
fi