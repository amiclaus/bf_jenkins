#!/bin/bash

USB_PATH=/dev/ttyUSB0
BAUDRATE=115200
BOARD_LABEL=$(lsblk -o label)

if [[ ${BOARD_LABEL} =~ "M2k" ]]
then
	echo "M2k"
elif [[ ${BOARD_LABEL} =~ "PlutoSDR" ]]
then
	echo "PlutoSDR"
elif [[ -e "$USB_PATH" ]]
then
	type screen &>/dev/null || sudo apt-get install -y screen &>/dev/null
	screen -S serial -L -d -m $USB_PATH $BAUDRATE
	screen -S serial -X logfile output_log
	sleep 5
	screen -S serial -X stuff 'cat /proc/device-tree/model\n\r'
	sleep 5
	screen -S serial -X stuff 'hostname -I\n\r'
	sleep 5
	screen -S serial -X quit
	
	if [[ $1 = 'board' ]]
	then
		cat output_log | head -2 | tail -1
	elif [[ $1 = 'ip' ]]
	then
		cat output_log | head -4 | tail -1
	fi

	rm output_log	
	
else
	echo "no USB device"
fi
