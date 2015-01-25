#!/bin/bash

declare remote_host
declare remote_port
declare remote_file
declare local_file
declare redirect_url
declare remote_file_len=0
declare remote_type=0
declare file_type=0
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

function br_handle_redirect()
{
        parse_url $redirect_url

        socket_create $remote_host $remote_port
        send_request $remote_host $remote_port $remote_file
        br_get_run
        display_finsh
        socket_close
}

function br_check_status()
{
	local http_status line

        read -u 9 -t 30 line
        http_status=`echo $line | awk '{print $2}'`

        case $http_status in
                "200")
                        echo "response 200 ok."
			;;
                "302")
                        echo "response 302 ok."
                        ;;
                *)
                        echo "bad http request: $line"
                        rm -f $local_file
                        socket_close
                        exit ;;
        esac
}

function br_check_type()
{
	local line tmp tmp1

        while read -u 9 -t 30 line
        do
                echo -e $line
                [ ${#line} -eq 1 ] && break

                tmp=`echo $line|cut -d " " -f 1`
                case $tmp in
                        "Content-Length:")
                                remote_file_len=`echo $line|cut -d " " -f 2`
                                remote_type=0 ;;
                        "Location:")
                                redirect_url=`echo $line|cut -d " " -f 2`
                                remote_type=1 ;;
                        "Transfer-Encoding:")
				tmp1=`echo $line|cut -d " " -f 2`
				if echo $tmp1| grep "chunked" >/dev/null ; then
                                	remote_type=2
				fi ;;
			"Content-Encoding:")
				tmp1=`echo $line|cut -d " " -f 2`
				if echo $tmp1| grep "gzip" >/dev/null ; then
                                	file_type=2
				fi ;;
                esac
        done
}

function br_handle_direct()
{
	local curr_file_len=0 idx=0 tmp

	echo "start direct download..."
        br_run_init

        tmp=${#remote_file_len}; ((tmp--))
        remote_file_len=${remote_file_len:0:$tmp}
	echo "length: $remote_file_len bytes."

        while [ $curr_file_len -le $remote_file_len ]
        do
                `dd bs=1024 count=1 of=$local_file seek=$idx <&9 2>/dev/null`
                ((idx++))
              	curr_file_len=$((idx*1024))
                br_run_play
        done
}

function br_convert_file()
{
	case $file_type in
		2)
			mv $local_file "$local_file.gz"
			gunzip -d "$local_file.gz"
			;;
	esac
}

function br_handle_chunk()
{
	local curr_file_len=0 idx=0 n tmp_file_len

	echo "start chunk download..."
        #br_run_init
        while read -u 9 -t 30 line
	do
		if [ ${#line} -eq 1 ]; then
			echo "download ok."
			break
		fi
		echo "!$line"

        	tmp_file_len=${#line}; ((tmp_file_len--))
        	remote_file_len=${line:0:$tmp_file_len}
		echo $remote_file_len
		remote_file_len=`printf "%d" "0x$remote_file_len"`
		echo "length: $remote_file_len bytes."

		tmp_file_len=$remote_file_len; n=1024
        	while [ $tmp_file_len -ne 0 ]
        	do
			if [ $tmp_file_len -lt 1024 ]; then
				n=$tmp_file_len
                		`dd bs=$n count=1 of="$local_file.tmp" seek=0 <&9 2>/dev/null`
			else
                		`dd bs=1024 count=1 of=$local_file seek=$idx <&9 2>/dev/null`
			fi
			tmp_file_len=$((tmp_file_len-n))
			curr_file_len=$((curr_file_len+n))
			((idx++))
                	#br_run_play
			#echo $curr_file_len $n $idx 
        	done

		if [ -a "$local_file.tmp" ]; then
			cat "$local_file.tmp" >> $local_file
			rm -f "$local_file.tmp"
		fi
	done

	br_convert_file
}

function br_get_run()
{
	br_check_status
	br_check_type

	echo $remote_type
	case $remote_type in
		0)
			br_handle_direct
			;;
		1)
			br_handle_redirect
			exit ;;
		2)
			br_handle_chunk
			;;
	esac
}

function br_send_request()
{
        local buf1 buf2 buf3 buf4 req_header

        buf1="GET /$3 http/1.0\r\nHost: $1:$2\r\n"
	buf2="Connection: keep-alive\r\nAccept: */*\r\n"
	buf3="Accept-Encoding: gzip, deflate\r\n"
	buf4="User-Agent: Mozilla/5.0 Chrome/39.0.2171.99 Safari/537.36\r\n"

	req_header=$buf1$buf2$buf3$buf4
	echo -e $req_header
        echo -e $req_header >&9
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

	echo $remote_host:$remote_port $remote_file
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
	echo -e "$0 <http_url> [local_file]"
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
        br_send_request $remote_host $remote_port $remote_file
	br_get_run
	display_finsh
        socket_close
}

main $@
