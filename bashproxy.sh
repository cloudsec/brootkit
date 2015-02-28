#!/bin/bash

mkfifo bd;cat bd|nc localhost 8899|nc localhost 8080 >bd
