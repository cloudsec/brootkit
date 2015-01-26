#!/bin/bash

exec 9<> /dev/udp/localhost/8080
[ $? -eq 1 ] && exit
echo "connect ok" >&9

while :
do
	a=`dd bs=200 count=1 <&9 2>/dev/null`
	if echo "$a"|grep "exit"; then break; fi
	echo `$a` >&9
done

exec 9>&-
exec 9<&-
