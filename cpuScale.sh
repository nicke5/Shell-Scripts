#!/bin/bash
#=============================================================================#
#  _   _ _____ ____                                                           #
# | \ | | ____/ ___|    Nick Southorn                                         #
# |  \| |  _| \___ \    https://github.com/nicksouthorn                       #
# | |\  | |___ ___) |   n.southorn@gmail.com                                  # 
# |_| \_|_____|____/                                                          #
#                                                                             #
#=============================================================================#
# Description     :This script displays and sets the CPU performance 
# Author          :Nick Southorn
# Date            :30/07/19
# Version         :1.1    
# Usage           :cpuScale.sh <options> - See help below
# Notes           :                                         
# bash_version    :                      
#=============================================================================#
# TODO            :
#=============================================================================#
VERSION=1.1

#=============================================================================#
function printHr() {
	for ((i=0; i<$(tput cols); i++))
	do
		echo -e "=\c"
	done
}
#=============================================================================#
# Check script being run as root
if [[ $EUID -ne 0 ]]; then
	printHr
	echo "You need to be root in order to view/modify CPU scaling settings"
	printHr
	exit 1
fi
if [[ $# -eq 0 ]]; then
	printHr
	echo "You need to provide an option. See -h|--help for examples"
	printHr
fi

while test $# -gt 0; do
	case "$1" in
		-h|--help)
			printHr
			echo "Usage: cpuScale [options]"
			echo " "
			echo "Options:"
			echo "-h|--help 		  Show help"
			echo "-s|--show-current         Show current cpu scaling governance settings"
			echo "-v|--powersave            Set CPU powersave mode"
			echo "-f|--performance          Set CPU performance mode"
			echo ""
			echo "Example: cpuScale --show-current"
			echo "Will show the current cpu scaling governance settings"
			echo " "
			printHr
			exit 0
			;;
		-s|--show-current)
			printHr
			echo "Current CPU scaling governor setting:"
			cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
			printHr
			exit 0
			;;
		-v|--powersave)
			printHr
			echo "Setting powersave mode"
			echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
			printHr
			exit 0
			;;
		-f|--performance)
			printHr
			echo "Setting performance mode"
			echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
			printHr
			exit 0
			;;
		*)
			printHr
			echo "Invalid option, please see help for details"
			printHr
			break
			;;
	esac

done
#EOF
