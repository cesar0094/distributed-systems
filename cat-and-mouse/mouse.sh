#!/bin/bash

# PORT=8081
PORT=$(cat nc_port_number)

state="chilling"

# first encounter
echo "Foundme" | nc -l $PORT

# second encounter
echo "Foundme" | nc -l $PORT

# attack encounter?
echo "Gotme" | nc -l $PORT

# nc -lk $PORT | while IFS=, read -a p
# do

# 	message=p[0]
# 	if [[ message == "MEOW" ]]; then
# 		if [[ $state == "chilling"]]; then
# 			# send go away
# 		elif [[ $state == "freaking out" ]]; then
# 			# send SIG_INT?
# 		fi
# 	fi

# done
