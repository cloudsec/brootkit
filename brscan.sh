#!/bin/bash

declare br_remote_host="localhost"
declare -a br_ports
declare br_port_num=0
declare br_thread_num=0
declare br_timeout=30
declare br_logfile="brscan.log"

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

# $1 => remote host
# $2 => remote port
# $3 => thread_num
function thread_scan()
{
	local i j k pid run_time sock_fd 

	mkdir -p .scan

	for ((i = 0; i < $3; i++))
	do
		{
		let "sock_fd=$2+$i"
		let "j=$2+$i+3"
		/bin/bash -c "exec $j<> /dev/tcp/$1/${br_ports[$sock_fd]}" 2>${br_ports[$sock_fd]}
		}&
		let "k=$2+$i"
		#echo $k ${br_ports[$k]} $!
		echo ${br_ports[$k]} > ".scan/$!"
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
			for aa in `ls .scan`
			do
				tport=`cat ".scan/$aa"`
				if [ $tport -eq ${br_ports[$sock_fd]} ]; then
                        		echo "connect to $1:${br_ports[$sock_fd]} ok."
				fi
			done
                fi
		
		rm -f ${br_ports[$sock_fd]}
	done

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
}

function br_parse_port()
{
	declare -a ports
	local tmp_ifs port

	tmp_ifs=$IFS; IFS=','
	ports=$1
	
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
	echo -ne "host: $br_remote_host | total ports: $br_port_num | thread num: $br_thread_num "
	echo -e "timeout: $br_timeout | logfile: $br_logfile\n"
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
	br_show_arg
	br_scan_port
}

main $@
