#!/bin/bash -
#title          :confight.sh
#description    :Script to enable/disable hyperthreading
#author         :Nick Southorn
#date           :20151110
#version        :1.0
#usage          :htconfight.sh -e (enable) | -d (disable) | -S (status)
#notes          :Currently hard coded to 12c CPUS - edit seq statement
#                to change, i.e. `seq 9 18` for a 10c CPU
#bash_version   :4.1.17(0)-release
#============================================================================
#TODO:  
#============================================================================
cat << EOF
==================================== HPC SYSTEM REPORT ======================================

HPC ICE-X Cluster

=============================================================================================

EOF


echo -e "ICE Cluster CPU: " $(/opt/c3/bin/cexec -p --all "cat /proc/cpuinfo | grep name " | awk -F':' '{print $3}' | sed 's/(R)//g' | awk '{print $1" "  $4" - " $6}' | uniq) "\n"

ht=$(/opt/c3/bin/cexec -p --all "cat /proc/cpuinfo | grep processor | wc -l" | awk -F':' '{print $2}' | awk '{total = total + $1}END{print total}') 
echo -e "Number of HT cores: "$ht "\n"
nht=$(echo $ht / 2 | bc)
echo -e "Number of Non-HT cores:" $nht "\n"

icememgb=$(/opt/c3/bin/cexec -p --all "free -g | grep -v cache | sed 's/://g' | grep Mem " | awk '{print $4}' | awk '{total = total + $1}END{print total}    ')
# icememgb=$(echo $icememmb / 1024 | bc)

echo -e "Total ICE memory: "$icememgb"Gb\n" 
echo ============================================================================================= 
cat << EOF
=============================================================================================

UV100 NUMA Cluster

=============================================================================================

EOF

echo -e "UV CPU: " $(ssh brx-hpc-uv1 "cat /proc/cpuinfo"  | grep name | uniq | awk -F':' '{print $2}' | sed 's/(R)//g' | awk '{print $1" " $4" - " $6}')"\n"
uvht=$(ssh brx-hpc-uv1 "cat /proc/cpuinfo | grep processor | wc -l ")
echo -e "Number of HT cores: " $uvht "\n"
uvnht=$(echo $uvht / 2 | bc)
echo -e "Number of Non-HT cores: " $uvnht "\n"
cset=$(ssh brx-hpc-uv1 "ls -d /dev/cpuset/*/"  | awk -F'/' '{print $4}')
echo -e "The following cpusets are defined:" 
for i in $cset; do echo $i":" $(ssh brx-hpc-uv1 "cat /dev/cpuset/$i/cpus"); done


echo -e "\nTotal UV memory: "$(ssh brx-hpc-uv1 "free -g" | grep Mem | awk '{print $2}')"Gb\n"

cat << EOF
=============================================================================================

PBS SETUP

=============================================================================================

EOF
echo -e "Primary PBS Server: "$(cat /etc/pbs.conf | grep PBS_PRIMARY | awk -F'=' '{print $2}')
echo -e "Secondary PBS Server: "$(cat /etc/pbs.conf | grep PBS_SECONDARY | awk -F'=' '{print $2}')
echo -e "PBS License File: "$(/opt/pbs/default/bin/qstat -Bf | grep pbs_license_file_location | awk -F'=' '{print $2}')







echo =============================================================================================

