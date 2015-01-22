#!/bin/bash

declare remote_host
declare remote_port
declare remote_file
declare local_file
declare remote_file_len=0
declare curr_file_len=0
declare max_col_num=64
declare total_run_time

function br_run_init()
{
	local i
	
	echo -ne "["
	for ((i = 1; i < $max_col_num; i++))
	do
		echo -ne " "
	done
	echo -ne "]\r"
}

function br_run_play()
{
        local i x y tmp_col

        tmp_col=$((curr_file_len * max_col_num / remote_file_len))

	echo -ne "["
        for ((i = 1; i < $tmp_col; i++))
        do
                echo -ne ">"
        done
	echo -ne "\r"
}

function br_run_finsh()
{
	echo -ne "\033[?25h"
}

function compute_run_time()
{
        local day hour min rtime

        day=$(($1/3600/24))
        hour=$(($1/3600))
        min=$(($1/60))

        if [ $min -eq 0 ]; then
                sec=$(($1%60))
                total_run_time="$sec s"
        else
                if [ $hour -eq 0 ]; then
                        sec=$(($1%60))
                        total_run_time="$min m $sec s"
                else
                        if [ $day -eq 0 ]; then
                                tmp=$(($1%3600))
                                min=$(($tmp/60))
                                sec=$(($tmp%60))
                                total_run_time="$hour h $min m $sec s"
                        else
                                # 86400 = 3600 * 24
                                tmp=$(($1%86400))
                                hour=$(($tmp/3600))
                                tmp1=$(($tmp%3600))
                                min=$(($tmp1/60))
                                sec=$(($tmp1%60))
                                total_run_time="$day d $hour h $min m $sec s"
                        fi


                fi
        fi
}

function get_run_time()
{
        local run_count local_hz run_time
        local start_time curr_time

        if [ -d "/proc/$1" ]; then
                run_count=`cat /proc/$1/stat | cut -d " " -f 22`
        else
                return 0
        fi

        local_hz=`getconf CLK_TCK`
        start_time=$(($run_count/$local_hz))

        curr_time=`cat /proc/uptime | cut -d " " -f 1 | cut -d "." -f 1`
        run_time=$((curr_time-start_time))

        return $run_time
}

function sock_read()
{
        local line tmp len=0 idx=0

        read -u 9 -t 5 line
        if ! echo $line|grep -e "200 OK" >/dev/null; then
                echo $line
		rm -f $remote_file
		socket_close
		exit
        else
		echo "response 200 ok."
	fi

        while read -u 9 -t 5 line
        do
		if [ ${#line} -eq 1 ]; then
			break
		fi

                tmp=`echo $line|cut -d " " -f 1`
                if [ "$tmp" == "Content-Length:" ]; then
                        remote_file_len=`echo $line|cut -d " " -f 2`
                fi
        done

	echo -e "length: $remote_file_len\n"

	br_run_init

	tmp=${#remote_file_len}
	((tmp--))
	remote_file_len=${remote_file_len:0:$tmp}

        while [ $curr_file_len -le $remote_file_len ]
        do
                `dd bs=1024 count=1 of=$local_file seek=$idx <&9 2>/dev/null`
                ((idx++))
                curr_file_len=$((idx*1024))
		br_run_play
        done

        #get_run_time $$
        #compute_run_time $?
        #echo -ne "\n$total_run_time"
}

function sock_write()
{
        local buf

        buf="GET /$3 http/1.0\r\nHost: $1:$2\r\n"
        echo -e $buf >&9
        [ $? -eq 0 ] && echo "send http request ok." || echo "send http request failed."
}

function socket_create()
{
        exec 9<> /dev/tcp/$1/$2
        [ $? -eq 0 ] && echo "connect to $1:$2 ok." || echo "connect to $1:$2 failed."
}

function socket_close()
{
        exec >&9-
        [ $? -ne 0 ] && echo "close socket failed."
}

function parse_url()
{
	local url=$1

	url=${url#http://}
	remote_file=${url#*/}

	[ -n "$2" ] && local_file=$2 || local_file=${url##*/}

	remote_host=`echo $url | awk -F '/' '{print $1}'`
	remote_port=`echo $remote_host | awk -F ':' '{print $2}'`
	remote_host=`echo $remote_host | awk -F ':' '{print $1}'`
	
	[ "$remote_port" == "" ] && remote_port=80
}

function file_init()
{
	[ -f $local_file ] && rm -f $local_file || touch $local_file
}

function display_start()
{
	local tmp

	tmp=`date +'%F %T'` 
	tmp="--$tmp-- $1"
	echo -e $tmp
}

function display_finsh()
{
	local tmp

	tmp=`date +'%F %T'` 
	tmp="\n\n--$tmp-- - $local_file saved $remote_file_len"
	echo -e "$tmp"
}

function brget_usage()
{
	echo -e "$0 <http_url> [local_file]\n"
	echo "exp:"
	echo "$0 http://www.baidu.com/index.html"
	echo "$0 http://www.baidu.com:80/index.html"
}

function main()
{
        if [ $# -eq 0 ]; then
		brget_usage $1
                exit
        fi

	parse_url $@

	file_init
	display_start $1
        socket_create $remote_host $remote_port
        sock_write $remote_host $remote_port $remote_file
        sock_read
	display_finsh
        socket_close
}

main $@
