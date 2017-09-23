_testBindMountManager() {
	_checkDep mount
	
	if ! mount --help | grep '\-\-bind' >/dev/null 2>&1
	then
		echo "mount missing bind feature"
		_stop 1
	fi
	
	if ! mount --help | grep '\-\-rbind' >/dev/null 2>&1
	then
		echo "mount missing rbind feature"
		_stop 1
	fi
	
}


# WARNING: Requries prior check with _mustGetSudo .
#"$1" == Source
#"$2" == Destination
_bindMountManager() {
	[[ ! -e "$1" ]] && return 1
	
	mkdir -p "$2"
	[[ ! -e "$2" ]] && return 1
	
	sudo -n mount --bind "$1" "$2"
} 