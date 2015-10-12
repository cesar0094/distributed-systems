#!/bin/bash

PORT=$(cat nc_port_number)

while true;
do
	echo "Listy waiting for message"
	nc -l $PORT >> cmsg

done
