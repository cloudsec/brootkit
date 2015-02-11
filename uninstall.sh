#!/bin/bash

BR_ROOTKIT_PATH="/usr/include/..."

declare br_os_type=0
declare br_privilege=1

function br_check_privilege()
{
        [ $UID -eq 0 -o $EUID -eq 0 ] && br_privilege=0 || br_privilege=1
}

function br_set_rootkit_path()
{
        if [ $br_privilege -eq 1 ]; then
                BR_ROOTKIT_PATH="/home/$USER/..."
        else
                echo "uninstall brootkit using root privilege."
        fi
}

function br_check_os_type()
{
        local line

        line=`head -n 1 /etc/issue`
        if echo $line|grep "[Cc]ent[Oo][Ss]" >/dev/null; then
                br_os_type=1
        elif echo $line|grep "[Rr]ed.Hat.Enterprise" >/dev/null; then
                br_os_type=2
        elif echo $line|grep "[Uu]buntu" >/dev/null; then
                br_os_type=3
        elif echo $line|grep "[Dd]ebian" >/dev/null; then
                br_os_type=4
        elif echo $line|grep "[Ff]edora" >/dev/null; then
                br_os_type=5
        else
                echo -e "target os type: $line is not supported."
                exit 0
        fi
}

function uninstall_backdoor()
{
	local pid

	for pid in `ps aux|grep bash|grep bashbd | awk '{print $2}'`
	do
        	kill -9 $pid >/dev/null 2>&1
	done
}

function uninstall_centos_home()
{
	local idx

        for idx in 0 1 2 3 4 5 6
        do
		rm -f /etc/rc.d/rc$idx.d/S10brdaemon
	done

	rm -fr /etc/profile.d/emacs.sh
	rm -fr /etc/rc.d/init.d/brdaemon
	rm -fr $BR_ROOTKIT_PATH
}

function uninstall_fedora_home()
{
        local idx

        for idx in 0 1 2 3 4 5 6
        do
                rm -f /etc/rc.d/rc$idx.d/S10brdaemon
        done

        rm -fr /etc/profile.d/emacs.sh
        rm -fr /etc/rc.d/init.d/brdaemon
        rm -fr $BR_ROOTKIT_PATH
}

function uninstall_ubuntu_home()
{
	local idx

        for idx in 0 1 2 3 4 5 6
        do
		rm -f /etc/rc$idx.d/S10brdaemon
	done
	rm -f /etc/rcS.d/S10brdaemon

	rm -fr /etc/profile.d/emacs.sh
	rm -fr /etc/init.d/brdaemon
	rm -fr $BR_ROOTKIT_PATH
}

function uninstall_debian_home()
{
	update-rc.d -f brdaemon remove

        rm -fr /etc/profile.d/emacs.sh
        rm -fr /etc/init.d/brdaemon
        rm -fr $BR_ROOTKIT_PATH
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

function main()
{
        br_check_os_type
	br_check_privilege
	br_set_rootkit_path
	uninstall_backdoor

	if [ $br_privilege -eq 0 ]; then
		uninstall_rootkit
        	case $br_os_type in
                	1|2)
                        	uninstall_centos_home ;;
                	3)
                        	uninstall_ubuntu_home ;;
                	4)
                        	uninstall_debian_home ;;
                	5)
                        	uninstall_fedora_home ;;
        	esac
	else
		rm -fr $BR_ROOTKIT_PATH
	fi

	exec /bin/bash
}

main
