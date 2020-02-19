#!/bin/bash

#----------------------------------#
# Functions section                #
#----------------------------------#

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

retry() {
	local retries="$1"
	shift
	while [ "$retries" -gt 0 ] ; do
		# run the commands
		$@
		[ "$?" == "0" ] && return 0
		echo_blue "   Retrying command ($retries): $@"
		sleep 1
		let retries='retries - 1'
	done
	echo_red "Command failed after $retries retries: $@"
	return 1
}

tolower() {
	echo "$1" | tr A-Z a-z
}

toupper() {
	echo "$1" | tr a-z A-Z
}

sudo_required() {
	type sudo &> /dev/null || {
		echo_red "'sudo' utility required"
		exit 1
	}
}

