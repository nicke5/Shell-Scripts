for CPU in /sys/devices/system/cpu/cpu[0-3]*; do
	CPUID=$(basename $CPU)
	echo "CPU: $CPUID";
	if test -e $CPU/online; then
		echo "1" > $CPU/online; 
	fi;
COREID="$(cat $CPU/topology/core_id)";
eval "COREENABLE=\"\${core${COREID}enable}\"";
if ${COREENABLE:-true}; then        
	echo "${CPU} core=${CORE} -> enable"
	eval "core${COREID}enable='false'";
else
	echo "$CPU core=${CORE} -> disable"; 
	echo "0" > "$CPU/online"; 
fi; 
done; 
