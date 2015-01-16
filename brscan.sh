#!/bin/bash

declare -a br_ports
declare br_port_num=0

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

	#for port in ${br_ports[@]}
	for ((i = 0; i < $br_port_num; i+=$2))
	do
		thread_scan $1 $i $2 
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

if [ $# -eq 0 ]; then
	echo "$0 <remote_host> <ports> <thread_num>"
	exit 0
fi

br_parse_port $2
br_scan_port $1 $3
