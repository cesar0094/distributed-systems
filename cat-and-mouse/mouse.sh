#!/bin/bash

PORT=$(cat nc_port_number)

while true;
do

	message=$(nc -l $PORT)

	if [[ "$message" == "MEOW" ]]; then
		chase_cat_pid=$(pgrep -f "chase_cat.sh")
		echo "They got me"
		kill -2 $chase_cat_pid
		exit 1
	fi

done
