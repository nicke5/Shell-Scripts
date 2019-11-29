#!/bin/bash -   
# Title         :pbsinfo.sh
# Description   :Displays information about PBS installation
# Author        :Nick Southorn
# Date          :29/11/19
# Version       :0.1    
# Usage         :./pbsinfo.sh
# Notes         :       
# Bash_Version  :5.0.11(1)-release
#==================================================================


# VARIABLES #
PBS_PRI=$(cat /etc/pbs.conf | grep PBS_PRIMARY | awk -F'=' '{print $2}')
PBS_SEC=$(cat /etc/pbs.conf | grep PBS_SECONDARY | awk -F'=' '{print $2}')
PBS_LIC=$(/opt/pbs/default/bin/qstat -Bf | \
	grep pbs_license_file_location | awk -F'=' '{print $2}')

# FUNCTIONS #


# MAIN #

echo -e "Primary PBS Server: " ${PBS_PRI}
echo -e "Secondary PBS Server: " ${PBS_SEC}
echo -e "PBS License File: " ${PBS_LIC}
