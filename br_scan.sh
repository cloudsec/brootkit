#!/bin/bash

# $1 => remote host
# $2 => remote port
# $3 => thread_num
function thread_scan()
{
	for ((i = 0; i < $3; i++))
	do
	{
		let "sock_fd=$2+$i"
		/bin/bash -c "echo $TMOUT;exec $sock_fd<> /dev/tcp/$1/$sock_fd" 2>"sock."$sock_fd
	}&
	done

	wait

	for ((i = 0; i < $3; i++))
	do
	{
		let "sock_fd=$2+$i"
                if [ -s "sock."$sock_fd ]; then
                        #echo -e "connect to $1:$sock_fd failed.\b"
                        echo -n ""
                else
                        echo "connect to $1:$sock_fd ok."
                fi
		
		rm -f "sock."$sock_fd
	}
	done
}

# $1 => remote host
# $2 => thread_num
function scan_port()
{
	for ((port = 21; port <= 80; port+=$2))
	do
	{
		thread_scan $1 $port $2 
	}
	done
}

if [ $# -eq 0 ]; then
	echo "$0 <remote_host> <thread_num>"
	exit 0
fi

scan_port $1 $2
