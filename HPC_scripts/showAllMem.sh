#!/bin/bash -
#title          :showallmem.sh
#description    :CEXEC script to return the memory on each compute node
#author         :Nick Southorn
#date           :20151110
#version        :1.0
#usage          :./showallmem.sh
#notes          :Run on SGI systems only - requires CEXEC
#bash_version   :4.1.17(0)-release
#========================================================================
# FUNCTIONS
#========================================================================
check_cexec(){
if ! [ "$(type -t /opt/c3/bin/cexec)" ]
then 
/usr/bin/clear
cat << EOF
= COMMAND NOT FOUND =====================================================

/opt/c3/bin/cexec not found.
Are you running this on a SGI ICE system with Tempo installed?

=========================================================================
EOF
/usr/bin/sleep 2
exit

}

/opt/c3/bin/cexec -p --all \
	"free -m \
	| grep -v Swap \
	| grep -v cache" \
	| sed 's/://g' \
	| awk 'BEGIN { print "Node       RAM(Mb)"
		       print "----       -------" }
		     { printf "%-10s %s\n", $2, $4 }'

