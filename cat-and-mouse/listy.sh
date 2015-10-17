#!/bin/bash

PORT=$(cat nc_port_number)

while true;
do
	echo "Listy waiting for message"
	message=$(nc -l $PORT)
	if [[ "$message" == "QUIT" ]]; then
		exit 1
	fi
	echo "$message" >> cmsg

done
