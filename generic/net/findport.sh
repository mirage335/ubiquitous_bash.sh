#http://unix.stackexchange.com/questions/55913/whats-the-easiest-way-to-find-an-unused-local-port
_findPort() {
	#read lower_port upper_port < /proc/sys/net/ipv4/ip_local_port_range
	lower_port=54000
	upper_port=55000
	
	while true
	do
		for (( port = lower_port ; port <= upper_port ; port++ )); do
			if ! ss -lpn | grep ":$port " > /dev/null 2>&1
			then
				sleep 0.1
				if ! ss -lpn | grep ":$port " > /dev/null 2>&1
				then
					break 2
				fi
			fi
		done
	done
	echo $port
}