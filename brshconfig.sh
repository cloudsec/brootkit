#!/bin/sh

br_load_config()
{
        local arg1 arg2 line

        while read line
        do
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

br_display_config()
{
        echo -e "HIDE_PORT:"
	echo $br_hide_port
        echo -e "HIDE_FILE:"
	echo $br_hide_file
        echo -e "HIDE_PROC:"
	echo $br_hide_proc
        echo -e "REMOTE_HOST:"
	echo $br_remote_host
        echo -e "REMOTE_PORT:"
	echo $br_remote_port
        echo -e "SLEEP_TIME:"
	echo $br_sleep_time
}

br_load_config "/home/$USER/.../brsh.conf"
#br_display_config
