#!/bin/bash -
#title          :confight.sh
#description    :Script to enable/disable hyperthreading
#author         :Nick Southorn
#date           :20151110
#version        :1.0
#usage          :htconfight.sh -e (enable) | -d (disable) | -S (status)
#notes          :Currently hard coded to 12c CPUS - edit seq statement
#		 to change, i.e. `seq 9 18` for a 10c CPU
#bash_version   :4.1.17(0)-release
#============================================================================
#TODO: Check for dmidecode
#TODO: Add auto detect number of CPUs
#============================================================================

cpuhome="/sys/devices/system/cpu"
htenable(){
	for i in `seq 12 23`
	do
	echo 1 > $cpuhome/cpu$i/online
	done
}
htdisable(){
	for i in `seq 12 23`
	do
	echo 0 > $cpuhome/cpu$i/online
	done
}
htcheck(){
nproc=$(grep -i "processor" /proc/cpuinfo | sort -u | wc -l)
phycore=$(cat /proc/cpuinfo | egrep "core id|physical id" | tr -d "\n" | sed s/physical/\\nphysical/g | grep -v ^$ | sort | uniq | wc -l)
if [ -z "$(echo "$phycore *2" | bc | grep $nproc)" ]
	then
		echo "Does not look like you have HT Enabled"
		if [ -z "$( dmidecode -t processor | grep HTT)" ]
			then
			echo "The CPUs on this system do not support Hyperthreading"
			else
			echo "Hyperthreading is disabled on this system"
		fi
	else
			echo "Hyperthreading is currently enabled"
fi

}

if ( ! getopts ":edS" opt); then
	echo "Usage: `basename $0` options (-e [enable] -d [disable] -S [status]) -h for help";
	exit $E_OPTERROR;
fi

printhelp(){
cat << EOF
=============================================================================================

confight.sh

Use this function to enable/disable Hyperthreading or show the current status.

Uasge: 
	-e - To enable
	-d - To disable
	-S - To show current HT status
	-h - To show this help message

=============================================================================================
EOF
exit

}
check_dmidecode(){
if ! [ "$(type -t /usr/sbin/dmidecode)" ]
then
/usr/bin/clear
cat << EOF

===================================== COMMAND NOT FOUND =====================================

dmidecode not found. Is this a Linux system?

=============================================================================================
EOF
/usr/bin/sleep 2
exit
fi
}

check_root(){
if [[ $EUID -ne 0 ]]
then
/usr/bin/clear
cat << EOF
=============================================================================================

You must be logged in as root to use this function

=============================================================================================

EOF
/usr/bin/sleep 2
exit

fi
}


while getopts ":edSh" opt; do
	case $opt in
		e)
		check_root
		echo "Hyperthreading turned on" >&2
		htenable
		;;
		d)
		check_root
		echo "Hyperthreading turned off" >&2
		htdisable
		;;
		S)
		check_root
		echo "Hyperthreading status" >&2
		htcheck
		;;
		h)
		printhelp
		;;
		\?)
		echo "Invalid option: -$OPTARG" >&2
		;;
	esac
done
