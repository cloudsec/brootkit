#!/bin/bash

declare remote_host
declare remote_port
declare remote_file
declare remote_file_len

function sock_read()
{
        local line tmp 

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

	echo "length: $remote_file_len"
        while read -u 9 -t 5 line
        do
                echo -e "$line" >>$remote_file
        done
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
	remote_host=`echo $url | awk -F '/' '{print $1}'`
	remote_port=`echo $remote_host | awk -F ':' '{print $2}'`
	remote_host=`echo $remote_host | awk -F ':' '{print $1}'`
	
	[ "$remote_port" == "" ] && remote_port=80
}

function file_init()
{
	[ -f $remote_file ] && rm -f $remote_file || touch $remote_file
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
	tmp="\n--$tmp-- - $remote_file saved $remote_file_len"
	echo -e "$tmp"
}

function wget_usage()
{
	echo -e "$0 <url>\n"
	echo "exp:"
	echo "$0 http://www.baidu.com/index.html"
	echo "$0 http://www.baidu.com:80/index.html"
}

function main()
{
        if [ $# -eq 0 ]; then
		wget_usage $1
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
