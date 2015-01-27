#!/bin/bash

function uninstall_backdoor()
{
	local pid

	for pid in `ps aux|grep bash|grep bashbd | awk '{print $2}'`
	do
        	kill -9 $pid
	done
}

function uninstall_home()
{
	local idx

        for idx in 0 1 2 3 4 5 6
        do
		rm -f /etc/rc.d/rc$idx.d/S10brdaemon
	done

	rm -fr /etc/profile.d/emacs.sh
	rm -fr /etc/rc.d/init.d/brdaemon
	rm -fr /usr/include/.../
}

function uninstall_rootkit()
{
	declare -a rootkit_hook=(
				"declare" "command" "builtin" "set"
				"fake_unset" "ls" "/bin/ls" "ps"
				"/bin/ps" "reset_ps" "netstat" "reset_netstat"
				"/bin/netstat" "type" "typeset" "abcdmagic"
				"reset_command" "su" "max_file_length"
				"dir" "/usr/bin/dir"
				)
	for hook_cmd in ${rootkit_hook[*]}
	do
		unset -f $hook_cmd
	done
}

uninstall_rootkit
uninstall_backdoor
uninstall_home
exec /bin/bash
