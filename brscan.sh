#!/bin/bash

declare br_remote_host="localhost"
declare -a br_ports
declare br_port_num=0
declare br_thread_num=0
declare br_timeout=30
declare br_logfile="brscan.log"

# $1 => remote host
# $2 => remote port
# $3 => thread_num
function thread_scan()
{
	local i

	for ((i = 0; i < $3; i++))
	do
	{
		let "sock_fd=$2+$i"
		/bin/bash -c "exec $sock_fd<> /dev/tcp/$1/${br_ports[$sock_fd]}" 2>"sock."$sock_fd
	}&
	done

	wait

	for ((i = 0; i < $3; i++))
	do
		let "sock_fd=$2+$i"
                if [ -s "sock."$sock_fd ]; then
                        #echo -e "connect to $1:${br_ports[$sock_fd]} failed.\b"
                        echo -n ""
                else
                        echo "connect to $1:${br_ports[$sock_fd]} ok."
                fi
		
		rm -f "sock."$sock_fd
	done
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
			br_parse_port $OPTARG
			;;
		n)
			br_thread_num=$OPTARG
			;;
		t)
			br_timeout=$OPTARG
			;;
		o)
			br_logfile=$OPTARG
			;;
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
