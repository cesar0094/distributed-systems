#!/bin/bash

LISTY_LOCATION=$(cat listy_location)
HOSTNAME=$(hostname)
WAIT_AFTER_ATTACK=8

MY_NAME=$2
ACTION=$1
TASK_TIME=$3
MOUSE_PORT=$(cat nc_port_number)
LISTY_PORT=$(cat nc_port_number)
TIMEOUT=1

function got_mouse() {
	# got the mouse
	echo "G $HOSTNAME $MY_NAME" | nc $LISTY_LOCATION $LISTY_PORT
	exit
}

function attack_mouse() {
	echo "MEOW" | nc localhost $MOUSE_PORT
	sleep $WAIT_AFTER_ATTACK
}

function search_for_mouse() {

	process_in_port=$(lsof -i :$MOUSE_PORT | grep nc | awk '{ print $2 }')

	if [[ "$process_in_port" != "" ]]; then
		echo "F $HOSTNAME $MY_NAME" | nc $LISTY_LOCATION $LISTY_PORT
	else
		echo "N $HOSTNAME $MY_NAME" | nc $LISTY_LOCATION $LISTY_PORT
	fi

}

trap got_mouse INT

# searching a node takes some time
# sleep $TASK_TIME
sleep 1

if [[ "$ACTION" == "S" ]]; then
	search_for_mouse
elif [[ "$ACTION" == "A" ]]; then
	attack_mouse
else
	echo "Unknown action: '$ACTION'"
fi
