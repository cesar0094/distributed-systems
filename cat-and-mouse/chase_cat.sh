#!/bin/bash

LISTY_LOCATION=$(cat listy_location)
HOSTNAME="localhost"
# HOSTNAME=$(hostname)

MY_NAME=$2
ACTION=$1
TASK_TIME=$3
MOUSE_PORT=8081
LISTY_PORT=$(cat nc_port_number)
TIMEOUT=1

# searching a node takes some time
# sleep TASK_TIME
sleep 1

message=$(echo "MEOW $MY_NAME" | nc $HOSTNAME $MOUSE_PORT -w $TIMEOUT)

echo "I $MY_NAME got message: '$message'"

if [[ $message == "" ]]; then
	# if we didn't find the mouse
	echo "N $HOSTNAME $MY_NAME" | nc $LISTY_LOCATION $LISTY_PORT
fi

if [[ $message == "Gotme" ]]; then
	# if we got the mouse
	echo "G $HOSTNAME $MY_NAME" | nc $LISTY_LOCATION $LISTY_PORT
fi

if [[ $message == "Foundme" ]]; then
	# if we found the mouse
	echo "F $HOSTNAME $MY_NAME" | nc $LISTY_LOCATION $LISTY_PORT
fi
