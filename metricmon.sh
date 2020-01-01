#!/bin/bash
#=============================================================================#
#  _   _ _____ ____                                                           #
# | \ | | ____/ ___|    Nick Southorn                                         #
# |  \| |  _| \___ \    https://github.com/nicksouthorn                       #
# | |\  | |___ ___) |   n.southorn@gmail.com                                  #
# |_| \_|_____|____/                                                          #
#                                                                             #
#=============================================================================#
# Description     :This script creates a number of directories, with a number 
#                  of dummy files in 
# Author          :Nick Southorn
# Date            :30/07/19
# Version         :1.2
# Usage           :genFakedirs [Number of Dirs] [Number of files per dir] \
#                       [chars per file]
# Notes           :
# bash_version    :
#=============================================================================#
# TODO            :
#=============================================================================#
VERSION=1.0
#=============================================================================#

#=============================================================================#
# FUNCTIONS
#=============================================================================#
function printHr() {
        for ((i=0; i<$(tput cols); i++))
        do
             echo -e "=\c"
        done
}



#=============================================================================#


DATE=$(date "+%d"-"%m"-"%y"-"%H%M")
POSITIONAL=()
while [[ $# -gt 0 ]]
do 
	key="$1"

case $key in
	-b|--battery)
	# VARS

	UPOWER="/usr/bin/upower -i"
	BAT0_PATH=/org/freedesktop/UPower/devices/battery_BAT0
	BAT1_PATH=/org/freedesktop/UPower/devices/battery_BAT1

	echo "BAT0,"$DATE","$($UPOWER $BAT0_PATH | grep "percentage" | sed -e "s/[a-zA-Z]//g" -e "s/://g"  -e "s/^[ \t]*//;s/[ \t]*$//")
	echo "BAT1,"$DATE","$($UPOWER $BAT1_PATH | grep "percentage" | sed -e "s/[a-zA-Z]//g" -e "s/://g"  -e "s/^[ \t]*//;s/[ \t]*$//")
	shift
	;;
	-c|--cputemp)
	# VARS
	SENSORS="/usr/bin/sensors"
	NUM_CORES=$($SENSORS | grep Core | wc -l)
	NUM_CORES1=$(expr $NUM_CORES - 1)

	for i in `seq 0 $NUM_CORES1`;
	do
		echo "Core$i,$DATE,"$($SENSORS | grep  "Core $i" | awk '{FS=":"}{print $3}' | sed -s "s/+//g")
	done
	shift
	;;
	-h|--help)
	echo "================= HELP =================="
	echo ""
	echo "Type metricmon.sh --usage to show options"	
	echo "" 
	echo "========================================="
	shift
	;;
	-u|--usage)
	echo "================ USAGE =================="
	echo ""
	echo "Show remaining battery percentage"
	echo "metricmon.sh -b|--battery"
	echo ""
	echo "Show CPU temperatures"
	echo "metricmon.sh -c|cputemp"
	echo ""
	echo "========================================="
	shift
	;;
	*)
	POSITIONAL+=("$1")
	shift
	;;
esac
done
set -- "${POSITIONAL[@]}"
