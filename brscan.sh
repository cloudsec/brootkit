#!/bin/bash

declare br_remote_host="localhost"
declare -a br_ports
declare -a br_open_ports
declare br_port_num=0
declare br_curr_port_num=0
declare br_open_port_num=0
declare br_thread_num=0
declare br_timeout=2
declare br_logfile="brscan.log"
declare total_run_time
declare max_row_num

declare -a playx=('/' '|' '\\' '-')
declare playx_len=4

declare max_col_num=64
declare base_row=0
declare base_col=1
declare cur_col=2
declare total_port=10
declare cur_port=0

function br_run_play()
{
        local i x y tmp_col

        tmp_col=$((br_curr_port_num * max_col_num / br_port_num))

        i=$((max_row_num+1))
        [ $br_thread_num -gt $i ] && x=$i || x=$((br_thread_num+4))

        for ((i = 1; i < $tmp_col; i++))
        do
                y=$((base_col+i))
                [ $y -gt $max_col_num ] && break
                echo -ne "\033[${x};${y}H>\033[?25l"
        done
}

function br_play_init()
{
        local x y i

        i=$((max_row_num+1))
        [ $br_thread_num -gt $i ] && x=$i || x=$((br_thread_num+4))

        echo -ne "\033[${x};${base_col}H\033[33m[\033[0m"

        y=$((max_col_num+1))
        echo -ne "\033[${x};${y}H\033[33m]\033[0m"
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

function br_show_open_ports()
{
	local run_time x y i

	get_run_time $$
	run_time=$?

	compute_run_time $run_time

	i=$((max_row_num+1))
	[ $br_thread_num -gt $i ] && x=$i || x=$((br_thread_num+4))

	y=$((max_col_num+3))
	printf "\033[${x};${y}H\033[32;1m %5d/%-5d\t$total_run_time\033[0m" \
		$br_curr_port_num $br_port_num

	x=$((x+2)); y=1
	printf "\033[${x};${y}H\033[32;1m%s: ${br_open_ports[*]}\033[0m" \
		$br_remote_host 
}

# $1 => remote host
# $2 => remote port
# $3 => thread_num
function thread_scan()
{
	local tport pid pidfile sock_fd
	local i j k m=0 run_time x

	mkdir -p .scan

	for ((i = 0; i < $3; i++))
	do
		{
		let "sock_fd=$2+$i"
		let "j=$2+$i+3"
		/bin/bash -c "exec $j<> /dev/tcp/$1/${br_ports[$sock_fd]}" 2>${br_ports[$sock_fd]}
		}&
		let "k=$2+$i"
		x=$((m+3))
		if [ $x -ge $max_row_num ]; then
			 m=0;x=3
		else
			((m++))
		fi
		printf "\033[${x};1H\033[33mthread<%-5d>\t\t--\t\tpid <%-5d>\t-->\t%-5d\033[?25l" \
			$i $! ${br_ports[$k]}
		echo ${br_ports[$k]} > ".scan/$!"
		[ $br_curr_port_num -ge $br_port_num ] && break || ((br_curr_port_num++))
	done

	sleep $br_timeout

	exec 2>&-
        for pid in `jobs -p`
        do
		get_run_time $pid
		run_time=$?
		[ $run_time -eq 0 ] && continue

                if [ $run_time -ge $br_timeout ]; then
                        kill -9 $pid >/dev/null 2>&1
			rm -f ".scan/$pid"
                fi
        done

	for ((i = 0; i < $3; i++))
	do
		let "sock_fd=$2+$i"
                if [ ! -s ${br_ports[$sock_fd]} ]; then
			for pid_file in `ls .scan`
			do
				tport=`cat ".scan/$pid_file"`
				if [ $tport -eq ${br_ports[$sock_fd]} ]; then
					br_open_ports[$br_open_port_num]=${br_ports[$sock_fd]}
					((br_open_port_num++))
				fi
			done
                fi
		
		rm -f ${br_ports[$sock_fd]}
	done

	br_run_play
	br_show_open_ports
	rm -fr .scan
}

# $1 => remote host
# $2 => thread_num
function br_scan_port()
{
	local i

	for ((i = 0; i < $br_port_num; i+=$br_thread_num))
	do
		thread_scan $br_remote_host $i $br_thread_num
	done
}

function br_show_ports()
{
	local i

	for ((i = 0; i < $br_port_num; i++))
	do
		echo ${br_ports[$i]}
	done
}

function parse_port()
{
	local start_port end_port port

	start_port=`echo $1 | cut -d "-" -f 1`
	end_port=`echo $1 | cut -d "-" -f 2`
	
	for ((port=$start_port; port <= $end_port; port++))
	do
		br_ports[$br_port_num]=$port
		((br_port_num++))
	done
	((br_port_num--))
}

function br_parse_port()
{
	declare -a ports
	local tmp_ifs port

	tmp_ifs=$IFS; IFS=','; ports=$1
	
	for port in ${ports[@]}
	do
		if echo $port|grep -e ".*-.*" >/dev/null; then
			parse_port $port
		else
			br_ports[$br_port_num]=$port
			((br_port_num++))
		fi
	done
	IFS=$tmp_ifs
}

function br_show_arg()
{
	echo -ne "\033[1;1H"
	echo -ne "\033[31;1mhost: $br_remote_host | total ports: $br_port_num | thread num: $br_thread_num "
	echo -e "timeout: $br_timeout | logfile: $br_logfile\n\033[0m"
}

function br_scan_init()
{
	echo -ne "\033[2J"
        MAX_ROW_NUM=`stty size|cut -d " " -f 1`
        MAX_COL_NUM=`stty size|cut -d " " -f 2`
	max_row_num=$((MAX_ROW_NUM-5))
}

function br_scan_exit()
{
	echo -e "\033[?25h"
}

function br_usage()
{
	echo -e "$1 <-p> [-n|-t|-o|-h] <remote_host>\n"
	echo -e "option:"
	echo -e "-p\t\tports, pattern: port1,port2,port3-port7,portn..."
	echo -e "-n\t\tthread num, defalut is 10"
	echo -e "-t\t\ttimeout, default is 30s"
	echo -e "-o\t\tresults write into log file, default is brscan.log"
	echo -e "-h\t\thelp information."
	echo -e "\nexp:"
	echo -e "$1 -p 21,22,23-25,80,135-139,8080 -t 20 www.cloud-sec.org"
	echo -e "$1 -p 1-65525 -n 200 -t 20 www.cloud-sec.org"
}

function main()
{
	if [ $# -eq 0 ]; then
		br_usage $0
		exit 0
	fi

	while getopts "p:n:t:o:h" arg
	do
	case $arg in
		p)
			br_parse_port $OPTARG ;;
		n)
			br_thread_num=$OPTARG ;;
		t)
			br_timeout=$OPTARG ;;
		o)
			br_logfile=$OPTARG ;;
		h)
			br_usage $0
			exit 0
			;;
		?)
			echo "unkown arguments."
			exit 1
			;;
		esac
	done
				
	shift $((OPTIND-1))
	br_remote_host=$@

	[ $br_port_num -lt $br_thread_num ] && br_thread_num=$br_port_num

	#br_show_ports
	br_scan_init
	br_play_init
	br_show_arg
	br_scan_port
	br_scan_exit
}

main $@
