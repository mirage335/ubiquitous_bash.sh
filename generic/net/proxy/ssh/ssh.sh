_testProxySSH() {
	_getDep ssh
	
	#For both _package and _rsync .
	! _wantDep rsync && echo 'warn: no rsync'
	
	! _wantDep base64 && echo 'warn: no base64'
	
	! _wantDep vncviewer && echo 'warn: no vncviewer, recommend tigervnc'
	! _wantDep vncserver && echo 'warn: no vncserver, recommend tigervnc'
	! _wantDep Xvnc && echo 'warn: no Xvnc, recommend tigervnc'
	
	! _wantDep x11vnc && echo 'warn: x11vnc not found'
	! _wantDep x0tigervncserver && echo 'warn: x0tigervncserver not found'
	
	! _wantDep vncpasswd && echo 'warn: vncpasswd not found, x11vnc broken!'
	
	! _wantDep xset && echo 'warn: xset not found'
	
	#! _wantDep xpra && echo 'warn: xpra not found'
	#! _wantDep xephyr && echo 'warn: xephyr not found'
	#! _wantDep xnest && echo 'warn: xnest not found'
	
	if [[ -e /usr/share/doc/realvnc-vnc-server ]] || type vnclicense >/dev/null 2>&1
	then
		echo 'TAINT: unsupported vnc!'
	fi
	
	#Desirable for _rsync backup.
	! _wantDep fakeroot && echo 'warn: fakeroot not found'
}

_testRemoteSSH() {
	_start
	_start_safeTmp_ssh "$@"
	
	_ssh "$@" "$safeTmpSSH"'/cautossh _test'
	
	_stop_safeTmp_ssh "$@"
	_stop
}

_ssh_self() {
	_start
	_start_safeTmp_ssh "$1"
	
	_ssh "$1" "$safeTmpSSH"'/cautossh '"$@"
	
	_stop_safeTmp_ssh "$1"
	_stop
}

_ssh_setupUbiquitous() {
	_start
	_start_safeTmp_ssh "$@"
	
	_ssh "$@" "$safeTmpSSH"'/cautossh _setupUbiquitous'
	
	_stop_safeTmp_ssh "$@"
	_stop
}

_ssh_setupUbiquitous_nonet() {
	_start
	_start_safeTmp_ssh "$@"
	
	_ssh "$@" "$safeTmpSSH"'/cautossh _setupUbiquitous_nonet'
	
	_stop_safeTmp_ssh "$@"
	_stop
}

#Enters remote server at hostname, by SSH, sets up a tunnel, checks tunnel for another SSH server.
#"$1" == host short name
#"$2" == port
#"$3" == remote host (optional, localhost default)
_checkRemoteSSH() {
	local localPort
	localPort=$(_findPort)
	
	local remoteHostDestination
	remoteHostDestination="$3"
	[[ "$remoteHostDestination" == "" ]] && remoteHostDestination="localhost"
	
	_timeout 14 _ssh -f "$1" -L "$localPort":"$remoteHostDestination":"$2" -N > /dev/null 2>&1
	sleep 2
	nmap -Pn localhost -p "$localPort" -sV 2> /dev/null | grep 'ssh' > /dev/null 2>&1 && return 0
	sleep 2
	nmap -Pn localhost -p "$localPort" -sV 2> /dev/null | grep 'ssh' > /dev/null 2>&1 && return 0
	sleep 2
	nmap -Pn localhost -p "$localPort" -sV 2> /dev/null | grep 'ssh' > /dev/null 2>&1 && return 0
	sleep 2
	nmap -Pn localhost -p "$localPort" -sV 2> /dev/null | grep 'ssh' > /dev/null 2>&1 && return 0
	sleep 3
	nmap -Pn localhost -p "$localPort" -sV 2> /dev/null | grep 'ssh' > /dev/null 2>&1 && return 0
	
	return 1
}

#Launches proxy if remote port is open at hostname.
#"$1" == gateway name
#"$2" == port
#"$3" == remote host (optional, localhost default)
_proxySSH() {
	local remoteHostDestination
	remoteHostDestination="$3"
	[[ "$remoteHostDestination" == "" ]] && remoteHostDestination="localhost"
	
	#Checking for remote port is usually unnecessary, as the SSH command seems to fail normally if the remote destination is not up. Not explicitly checking with nmap saves significant time (performance). However, the code remains in place for immediate return to default if proven useful.
	#if _checkRemoteSSH "$1" "$2" "$remoteHostDestination"
	#then
		if _ssh -q -W "$remoteHostDestination":"$2" "$1"
		then
			_stop
		fi
	#fi
	
	return 0
}

#Checks all reverse port assignments through hostname, launches proxy if open.
#"$1" == host short name
#"$2" == gateway name
_proxySSH_reverse() {
	_get_reversePorts "$1"
	
	local currentReversePort
	for currentReversePort in "${matchingReversePorts[@]}"
	do
		_proxySSH "$2" "$currentReversePort"
	done
}

_ssh_sequence() {
	_start
	
	export sshBase="$safeTmp"/.ssh
	_prepare_ssh
	
	#_setup_ssh
	_setup_ssh_operations
	
	local sshExitStatus
	ssh -F "$sshDir"/config "$@"
	sshExitStatus="$?"
	
	#Preventative workaround, not normally necessary.
	stty echo > /dev/null 2>&1
	
	_setup_ssh_merge_known_hosts
	
	_stop "$sshExitStatus"
}

_ssh() {
	if [[ "$sshInContainment" == "true" ]]
	then
		if ssh -F "$sshDir"/config "$@"
		then
			return 0
		fi
		return 1
	fi
	
	export sshInContainment="true"
	
	local sshExitStatus
	"$scriptAbsoluteLocation" _ssh_sequence "$@"
	sshExitStatus="$?"
	
	export sshInContainment=""
	
	return "$sshExitStatus"
}


#"$1" == commandName
_ssh_command_user_field() {
	echo "$1" | grep '^_ssh$' > /dev/null 2>&1 && return 1
	echo "$1" | grep '^_ssh' > /dev/null 2>&1 && echo "$1" | sed 's/^_ssh-//g' && return 0
	echo "$1" | grep '^_rsync$' > /dev/null 2>&1 && return 1
	echo "$1" | grep '^_rsync' > /dev/null 2>&1 && echo "$1" | sed 's/^_rsync-//g' && return 0
	
	echo "$1" | grep '^_backup$' > /dev/null 2>&1 && return 1
	echo "$1" | grep '^_backup' > /dev/null 2>&1 && echo "$1" | sed 's/^_backup-//g' && return 0
	
	return 1
}

#"$1" == commandName
_ssh_command_user() {
	local field_sshCommandUser
	field_sshCommandUser=$(_ssh_command_user_field "$1")
	
	#Output blank, default user specified by SSH config or here document.
	[[ "$field_sshCommandUser" == "home" ]] && return 0
	
	[[ "$field_sshCommandUser" != "" ]] && echo "$field_sshCommandUser" && return 0
	
	#Blank may be regarded as error condition.
	return 1
	
}

_ssh_command_machine() {
	true
}

_rsync_command_check_backup_dependencies() {
	#_messageNormal "Checking - dependencies."
	
	##Check for sudo, especially if fakeroot is unavailable or undesirable.
	#if [[ "$criticalSSHUSER" == "root" ]]
	#then
		#[[ $(id -u) != 0 ]] && _messageError 'fail: not root' && return 1
		criticalSudoAvailable=false
		criticalSudoAvailable=$(sudo -n echo true)
		! [[ "$criticalSudoAvailable" == "true" ]] && _messageError 'bad: sudo' && return 1
	#fi

	#Check for fakeroot.
	#! type fakeroot > /dev/null 2>&1  && _messageError 'missing: fakeroot' && return 1
	
	# WARNING Intended for direct copy/paste inclusion into independent launch wrapper scripts. Kept here for redundancy.
	! type _command_safeBackup > /dev/null 2>&1 && _messageError "missing: _command_safeBackup" && return 1
	
	return 0
}

#"$1" == criticalBackupSource
#"$2" == criticalBackupDestination
_prepare_rsync_backup_env() {
	_messageNormal "Preparing - env."
	
	[[ "$1" != "" ]] && export criticalBackupSource="$1"
	[[ "$2" != "" ]] && export criticalBackupDestination="$2"

	[[ "$criticalBackupSource" == "" ]] && _messageError 'blank: criticalBackupSource' && return 1
	[[ "$criticalBackupDestination" == "" ]] && _messageError 'blank: criticalBackupDestination' && return 1

	mkdir -p "$criticalBackupDestination"
	[[ ! -e "$criticalBackupDestination" ]] && _messageError 'fail: mkdir criticalBackupDestination= '"$criticalBackupDestination" && return 1

	mkdir -p "$criticalBackupDestination"/fs
	[[ ! -e "$criticalBackupDestination"/fs ]] && _messageError 'fail: mkdir criticalBackupDestination/fs= '"$criticalBackupDestination"/fs && return 1
	
	! sudo -n chown root:root "$criticalBackupDestination"/fs && _messageError 'chown: '"$criticalBackupDestination" && return 1
	! sudo -n chmod 700 "$criticalBackupDestination"/fs && _messageError 'chmod: '"$criticalBackupDestination" && return 1

	#Fakeroot, pseudo, and image, optional features are provisioned here, but not expected to be used. Containing all operations within Uqibuitous Bash virtualization is generally expected to represent best practice.

	#mkdir -p "$criticalBackupDestination"/fakeroot
	#[[ ! -e "$criticalBackupDestination"/fakeroot ]] && _messageError 'fail: mkdir criticalBackupDestination/fakeroot= '"$criticalBackupDestination"/fakeroot && return 1
	#[[ ! -e "$criticalBackupDestination"/fakeroot.db ]] && echo -n > "$criticalBackupDestination"/fakeroot.db
	#[[ ! -e "$criticalBackupDestination"/fakeroot.db ]] && _messageError 'fail: mkdir criticalBackupDestination/fakeroot.db= '"$criticalBackupDestination"/fakeroot.db && return 1

	#mkdir -p "$criticalBackupDestination"/pseudo
	#[[ ! -e "$criticalBackupDestination"/pseudo ]] && _messageError 'fail: mkdir criticalBackupDestination/pseudo= '"$criticalBackupDestination"/pseudo && return 1
	#[[ ! -e "$criticalBackupDestination"/pseudo.db ]] && echo -n > "$criticalBackupDestination"/pseudo.db
	#[[ ! -e "$criticalBackupDestination"/pseudo.db ]] && _messageError 'fail: mkdir criticalBackupDestination/pseudo.db= '"$criticalBackupDestination"/pseudo.db && return 1

	#mkdir -p "$criticalBackupDestination"/image
	#[[ ! -e "$criticalBackupDestination"/image ]] && _messageError 'fail: mkdir criticalBackupDestination/image= '"$criticalBackupDestination"/image && return 1
	#[[ ! -e "$criticalBackupDestination"/image.img ]] && echo -n > "$criticalBackupDestination"/image.img
	#[[ ! -e "$criticalBackupDestination"/image.img ]] && _messageError 'fail: mkdir criticalBackupDestination/image.img= '"$criticalBackupDestination"/image.img && return 1
	
	! _safeBackup "$criticalBackupDestination" && _messageError "check: _command_safeBackup" && return 1
	
	return 0
}

# WARNING Sets and accepts global variables. Do NOT reuse or recurse without careful consideration or guard statements.
#Generates "root@machine:/" format rsync address from machine name, user, and path.
#_rsync_sourceAddress "machine" "/path/" "user"
#_rsync_sourceAddress "machine" "" "user"
#"$1" == criticalSSHmachine
#"$2" == criticalSourcePath (optional)
#"$3" == criticalUser (optional)
_rsync_remoteAddress() {
	#root@machine:/
	#user@machine:
	#machine:
	
	[[ "$1" != "" ]] && export criticalSSHmachine="$1"
	[[ "$2" != "" ]] && export criticalSourcePath="$2"
	[[ "$3" != "" ]] && export criticalUser="$3"
	
	[[ "$criticalSourcePath" == "" ]] && [[ "$criticalUser" == "root" ]] && export criticalSourcePath="/"
	
	export criticalUserAddress="$criticalUser"
	[[ "$criticalUserAddress" != "" ]] && export criticalUserAddress="$criticalUser"'@'
	
	export criticalRsyncAddress="$criticalUserAddress""$criticalSSHmachine"':'"$criticalSourcePath"
	
	echo "$criticalRsyncAddress"
	
	[[ "$criticalSSHmachine" == "" ]] && return 1
	return 0
}

# WARNING Sets and accepts global variables. Do NOT reuse or recurse without careful consideration or guard statements.
#"$1" == criticalSSHmachine
#"$2" == criticalSourcePath (optional)
#"$3" == criticalUser (optional)
#"$4" == commandName
#_rsync_backup_remote "$machineName" "" "" "$commandName"
_rsync_backup_remote() {
	[[ "$1" != "" ]] && export criticalSSHmachine="$1"
	[[ "$2" != "" ]] && export criticalSourcePath="$2"
	[[ "$3" != "" ]] && export criticalUser="$3"
	
	[[ "$criticalUser" == "" ]] && export criticalUser=$(_ssh_command_user "$4")
	
	[[ "$criticalSSHmachine" == "" ]] && return 1
	
	_rsync_remoteAddress "$criticalSSHmachine" "$criticalSourcePath" "$criticalUser"
}

# WARNING Sets and accepts global variables. Do NOT reuse or recurse without careful consideration or guard statements.
#"$1" == criticalDestinationPrefix (optional, default "_arc")
#"$2" == $criticalDestinationPath (optional)
#"$3" == criticalUser (optional)
#"$4" == commandName
#_rsync_backup_local "" "" "" "$commandName"
_rsync_backup_local() {
	[[ "$1" != "" ]] && export criticalDestinationPrefix="$1"
	[[ "$criticalDestinationPrefix" == "" ]] && export criticalDestinationPrefix="_arc"
	
	[[ "$3" != "" ]] && export criticalUser="$3"
	[[ "$criticalUser" == "" ]] && export criticalUser=$(_ssh_command_user_field "$4")
	
	[[ "$2" != "" ]] && export criticalDestinationPath="$2"
	[[ "$criticalDestinationPath" == "" ]] && export criticalDestinationPath="$criticalUser"
	
	[[ "$criticalDestinationPath" == "" ]] && return 1
	
	export criticalDestinationPrefixAddress="$criticalDestinationPrefix"
	[[ "$criticalDestinationPrefixAddress" != "" ]] && export criticalDestinationPrefixAddress="$criticalDestinationPrefixAddress"'/'
	
	echo "$criticalDestinationPrefixAddress""$criticalDestinationPath"
}

_rsync() {
	rsync -e "$scriptAbsoluteLocation"" _ssh" "$@"
}

_start_safeTmp_ssh() {
	cat "$scriptAbsoluteLocation" | base64 | _ssh -C -o ConnectionAttempts=2 "$@" '
mkdir -p '"$safeTmpSSH"'
chmod 700 '"$safeTmpSSH"'
cat - | base64 -d > '"$safeTmpSSH"'/cautossh
chmod 700 '"$safeTmpSSH"'/cautossh
'
	
	#cat "$scriptAbsoluteLocation" | base64 | _ssh -C -o ConnectionAttempts=2 "$@" 'cat - | base64 -d > '"$safeTmpSSH"'/cautossh'
	#_ssh -C -o ConnectionAttempts=2 "$@" 'chmod 700 '"$safeTmpSSH"'/cautossh'
}

_stop_safeTmp_ssh() {
#rm '"$safeTmpSSH"'/w_*/*
	cat "$scriptAbsoluteLocation" | _ssh -C -o ConnectionAttempts=2 "$@" '
rm '"$safeTmpSSH"'/cautossh
rmdir '"$safeTmpSSH"'/_local
rmdir '"$safeTmpSSH"'
'
	
}

_vnc_ssh() {
	"$scriptAbsoluteLocation" _ssh -C -c aes256-gcm@openssh.com -m hmac-sha1 -o ConnectionAttempts=2 -o ServerAliveInterval=5 -o ServerAliveCountMax=5 -o ExitOnForwardFailure=yes "$@" 
}

_findPort_vnc() {
	local vncMinPort
	let vncMinPort="${reversePorts[0]}"+20
	
	local vncMaxPort
	let vncMaxPort="${reversePorts[0]}"+50
	
	_findPort "$vncMinPort" "$vncMaxPort"
}

_prepare_vnc() {
	
	echo > "$vncPasswdFile".pln
	chmod 600 "$vncPasswdFile".pln
	_uid 8 > "$vncPasswdFile".pln
	
	export vncPort=$(_findPort_vnc)
	
	export vncPIDfile="$safeTmpSSH"/.vncpid
	export vncPIDfile_local="$safeTmp"/.vncpid
	
}

_report_vncpasswd() {
	_messagePlain_probe 'report: _report_vncpasswd'
	
	! [[ -e "$vncPasswdFile".pln ]] && _messagePlain_bad 'missing: "$vncPasswdFile".pln' && return 0
	
	! [[ -s "$vncPasswdFile".pln ]] && _messagePlain_bad 'blank: "$vncPasswdFile".pln' && return 0
	
	if [[ -s "$vncPasswdFile".pln ]]
	then
		#Blue. Diagnostic instrumentation.
		echo -e -n '\E[0;34m '
		cat "$vncPasswdFile".pln
		echo -e -n ' \E[0m'
		echo
		return 0
	fi
	
	return 0
}

_vncpasswd() {
	_messagePlain_nominal "init: _vncpasswd"
	
	#TigerVNC, specifically.
	if type tigervncpasswd >/dev/null 2>&1
	then
		_messagePlain_good 'found: tigervnc'
		_report_vncpasswd
		! echo | cat "$vncPasswdFile".pln - "$vncPasswdFile".pln | tigervncpasswd "$vncPasswdFile" && _messagePlain_bad 'fail: vncpasswd' && return 1
		return 0
	fi
	
	#Supported by both TightVNC and TigerVNC.
	if echo | vncpasswd -x --help 2>&1 | grep -i 'vncpasswd \[FILE\]' >/dev/null 2>&1
	then
		_messagePlain_good 'found: vncpasswd'
		_report_vncpasswd
		! echo | cat "$vncPasswdFile".pln - "$vncPasswdFile".pln | vncpasswd "$vncPasswdFile" && _messagePlain_bad 'fail: vncpasswd' && return 1
		return 0
	fi
	
	type vncpasswd > /dev/null 2>&1 && _messagePlain_bad 'unsupported: vncpasswd'
	! type vncpasswd > /dev/null 2>&1 && _messagePlain_bad 'missing: vncpasswd'
	
	return 1
}

_vncviewer_operations() {
	_messagePlain_nominal 'init: _vncviewer_operations'
	
	_messagePlain_nominal 'Searching for X11 display.'
	! _detect_x11 && _messagePlain_warn 'fail: _detect_x11'
	
	export DISPLAY="$destination_DISPLAY"
	export XAUTHORITY="$destination_AUTH"
	_messagePlain_probe '_vncviewer_operations'
	_report_detect_x11
	
	_messagePlain_nominal 'Detecting and launching vncviewer.'
	#TigerVNC
	if vncviewer --help 2>&1 | grep 'PasswordFile   \- Password file for VNC authentication (default\=)' >/dev/null 2>&1
	then
		_messagePlain_good 'found: vncviewer (TigerVNC)'
		
		if ! vncviewer -DotWhenNoCursor -passwd "$vncPasswdFile" localhost:"$vncPort" "$@"
		then
			_messagePlain_bad 'fail: vncviewer'
			stty echo > /dev/null 2>&1
			return 1
		fi
		stty echo > /dev/null 2>&1
		return 0
	fi
	
	#TightVNC
	if vncviewer --help 2>&1 | grep '\-passwd' >/dev/null 2>&1
	then
		_messagePlain_good 'found: vncviewer (TightVNC)'
		
		#if ! vncviewer -encodings "copyrect tight zrle hextile" localhost:"$vncPort"
		if ! vncviewer -passwd "$vncPasswdFile" localhost:"$vncPort" "$@"
		then
			_messagePlain_bad 'fail: vncviewer'
			stty echo > /dev/null 2>&1
			return 1
		fi
		stty echo > /dev/null 2>&1
		return 0
	fi
	
	type vncviewer > /dev/null 2>&1 && _messagePlain_bad 'unsupported: vncviewer'
	! type vncviewer > /dev/null 2>&1 && _messagePlain_bad 'missing: vncviewer'
	
	return 1
}

_vncviewer_sequence() {
	_messageNormal '_vncviewer_sequence: Start'
	_start
	
	_messageNormal '_vncviewer_sequence: Setting vncpasswd .'
	cat - > "$vncPasswdFile".pln
	_report_vncpasswd
	! _vncpasswd && _messageError 'FAIL: vncpasswd' && _stop 1
	
	_messageNormal '_vncviewer_sequence: Operations .'
	! _vncviewer_operations "$@" && _messageError 'FAIL: vncviewer' && _stop 1
	
	_messageNormal '_vncviewer_sequence: Stop'
	_stop
}

#Password must be given on standard input. Environment variable "$vncPort" must be set. Environment variable "$destination_DISPLAY" may be forced.
_vncviewer() {
	"$scriptAbsoluteLocation" _vncviewer_sequence "$@"
}

#To be overrideden by ops (eg. for "-repeat").
_x11vnc_command() {
	x11vnc "$@"
}

_x11vnc_operations() {
	_messagePlain_nominal 'init: _x11vnc_operations'
	
	_messagePlain_nominal 'Searching for X11 display.'
	! _detect_x11 && _messagePlain_bad 'fail: _detect_x11'
	
	export DISPLAY="$destination_DISPLAY"
	export XAUTHORITY="$destination_AUTH"
	_messagePlain_probe 'x11vnc_operations'
	_report_detect_x11
	
	_messagePlain_nominal 'Detecting and launching x11vnc.'
	#x11vnc
	if type x11vnc >/dev/null 2>&1
	then
		_messagePlain_good 'found: x11vnc'
		
		#-passwdfile cmd:"/bin/cat -"
		#-noxrecord -noxfixes -noxdamage
		if ! _x11vnc_command -localhost -rfbauth "$vncPasswdFile" -rfbport "$vncPort" -timeout 16 -xkb -display "$destination_DISPLAY" -auth "$destination_AUTH" -noxrecord -noxdamage
		then
			_messagePlain_bad 'fail: x11vnc'
			return 1
		fi
		
		return 0
	fi
	
	#TigerVNC.
	if type x0tigervncserver
	then
		_messagePlain_good 'found: x0tigervncserver'
		
		if ! x0tigervncserver -rfbauth "$vncPasswdFile" -rfbport "$vncPort"
		then
			_messagePlain_bad 'fail: x0tigervncserver'
			return 1
		fi
		return 0
	fi
	
	_messagePlain_bad 'missing: x11vnc || x0tigervncserver'
	
	return 1
}

_x11vnc_sequence() {
	_messageNormal '_x11vnc_sequence: Start'
	_start
	
	_messageNormal '_x11vnc_sequence: Setting vncpasswd .'
	cat - > "$vncPasswdFile".pln
	_report_vncpasswd
	! _vncpasswd && _messageError 'FAIL: vncpasswd' && _stop 1
	
	_messageNormal '_x11vnc_sequence: Operations .'
	! _x11vnc_operations && _messageError 'FAIL: x11vnc' && _stop 1
	
	_messageNormal '_x11vnc_sequence: Stop'
	_stop
}

#Password must be given on standard input. Environment variable "$vncPort" must be set. Environment variable "$destination_DISPLAY" may be forced.
_x11vnc() {
	"$scriptAbsoluteLocation" _x11vnc_sequence "$@"
}

_vncserver_operations() {
	_messagePlain_nominal 'init: _vncserver_operations'
	
	#[[ "$desktopEnvironmentLaunch" == "" ]] && desktopEnvironmentLaunch="true"
	[[ "$desktopEnvironmentLaunch" == "" ]] && desktopEnvironmentLaunch="startlxde"
	[[ "$desktopEnvironmentGeometry" == "" ]] && desktopEnvironmentGeometry='1920x1080'
	
	_messagePlain_nominal 'Searching for unused X11 display.'
	local vncDisplay
	local vncDisplayValid
	for (( vncDisplay = 1 ; vncDisplay <= 9 ; vncDisplay++ ))
	do
		! [[ -e /tmp/.X"$vncDisplay"-lock ]] && ! [[ -e /tmp/.X11-unix/X"$vncDisplay" ]] && vncDisplayValid=true && _messagePlain_good 'found: unused X11 display= '"$vncDisplay" && break
	done
	[[ "$vncDisplayValid" != "true" ]] && _messagePlain_bad 'fail: vncDisplayValid != "true"' && _stop 1
	
	_messagePlain_nominal 'Detecting and launching vncserver.'
	#TigerVNC
	if echo | vncserver -x --help 2>&1 | grep '\-fg' >/dev/null 2>&1
	then
		_messagePlain_good 'found: vncserver (TigerVNC)'
		echo
		echo '*****TigerVNC Server Detected'
		echo
		#"-fg" may be unreliable
		#vncserver :"$vncDisplay" -depth 16 -geometry "$desktopEnvironmentGeometry" -localhost -rfbport "$vncPort" -rfbauth "$vncPasswdFile" &
		
		
		export XvncCommand="Xvnc"
		type Xtigervnc >/dev/null 2>&1 && export XvncCommand="Xtigervnc"
		
		type "$XvncCommand" > /dev/null 2>&1 && _messagePlain_good 'found: XvncCommand= '"$XvncCommand"
		! type "$XvncCommand" > /dev/null 2>&1 && _messagePlain_bad 'missing: XvncCommand= '"$XvncCommand"
		
		"$XvncCommand" :"$vncDisplay" -depth 16 -geometry "$desktopEnvironmentGeometry" -localhost -rfbport "$vncPort" -rfbauth "$vncPasswdFile" &
		echo $! > "$vncPIDfile"
		
		sleep 0.3
		[[ ! -e "$vncPIDfile" ]] && _messagePlain_bad 'missing: "$vncPIDfile"' && return 1
		local vncPIDactual=$(cat $vncPIDfile)
		! ps -p "$vncPIDactual" > /dev/null 2>&1 && _messagePlain_bad 'inactive: vncPID= '"$vncPIDactual" && return 1
		
		export DISPLAY=:"$vncDisplay"
		
		local currentCount
		for (( currentCount = 0 ; currentCount < 90 ; currentCount++ ))
		do
			xset q >/dev/null 2>&1 && _messagePlain_good 'connect: display= '"$DISPLAY" && break
			sleep 1
		done
		
		[[ "$currentCount" == "90" ]] && _messagePlain_bad 'fail: connect: display= '"$DISPLAY" && return 1
		
		bash -c "$desktopEnvironmentLaunch" &
		
		sleep 12
		
		return 0
	fi
	
	#TightVNC
	if type vncserver >/dev/null 2>&1
	then
		_messagePlain_good 'found: vncserver (TightVNC)'
		echo
		echo '*****TightVNC Server Detected'
		echo
		
		#TightVNC may refuse to use an aribtary password file if system default does not exist.
		[[ ! -e "$HOME"/.vnc/passwd ]] && echo | cat "$vncPasswdFile".pln - "$vncPasswdFile".pln | vncpasswd
		
		export XvncCommand="Xvnc"
		type Xtightvnc >/dev/null 2>&1 && export XvncCommand="Xtightvnc"
		
		type "$XvncCommand" > /dev/null 2>&1 && _messagePlain_good 'found: XvncCommand= '"$XvncCommand"
		! type "$XvncCommand" > /dev/null 2>&1 && _messagePlain_bad 'missing: XvncCommand= '"$XvncCommand"
		
		"$XvncCommand" :"$vncDisplay" -depth 16 -geometry "$desktopEnvironmentGeometry" -nevershared -dontdisconnect -localhost -rfbport "$vncPort" -rfbauth "$vncPasswdFile" -rfbwait 12000 &
		echo $! > "$vncPIDfile"
		
		sleep 0.3
		[[ ! -e "$vncPIDfile" ]] && _messagePlain_bad 'missing: "$vncPIDfile"' && return 1
		local vncPIDactual=$(cat $vncPIDfile)
		! ps -p "$vncPIDactual" > /dev/null 2>&1 && _messagePlain_bad 'inactive: vncPID= '"$vncPIDactual" && return 1
		
		export DISPLAY=:"$vncDisplay"
		
		local currentCount
		for (( currentCount = 0 ; currentCount < 90 ; currentCount++ ))
		do
			xset q >/dev/null 2>&1 && _messagePlain_good 'connect: display= '"$DISPLAY" && break
			sleep 1
		done
		
		[[ "$currentCount" == "90" ]] && _messagePlain_bad 'fail: connect: display= '"$DISPLAY" && return 1
		
		bash -c "$desktopEnvironmentLaunch" &
		
		sleep 12
		
		return 0
	fi
	
	type vncserver > /dev/null 2>&1 && type Xvnc > /dev/null 2>&1 && _messagePlain_bad 'unsupported: vncserver || Xvnc' && return 1
	
	_messagePlain_bad 'missing: vncserver || Xvnc'
	
	return 1
}

_vncserver_sequence() {
	_messageNormal '_vncserver_sequence: Start'
	_start
	
	_messageNormal '_vncserver_sequence: Setting vncpasswd .'
	cat - > "$vncPasswdFile".pln
	! _vncpasswd && _messageError 'FAIL: vncpasswd' && _stop 1
	
	_messageNormal '_x11vnc_sequence: Operations .'
	! _vncserver_operations && _messageError 'FAIL: vncserver' && _stop 1
	
	_stop
}

#Password must be given on standard input. Environment variables "$vncPort", "$vncPIDfile", must be set. Environment variables "$desktopEnvironmentGeometry", "$desktopEnvironmentLaunch", may be forced.
_vncserver() {
	"$scriptAbsoluteLocation" _vncserver_sequence "$@"
}

#Environment variable "$vncPIDfile", must be set.
_vncserver_terminate() {
	
	# WARNING: For now, this does not always work with TigerVNC.
	if [[ -e "$vncPIDfile" ]] && [[ -s "$vncPIDfile" ]]
	then
		_messagePlain_good 'found: usable "$vncPIDfile"'
		
		pkill -P $(cat "$vncPIDfile")
		kill $(cat "$vncPIDfile")
		#sleep 1
		#kill -KILL $(cat "$vncPIDfile")
		rm "$vncPIDfile"
		
		pgrep Xvnc && _messagePlain_warn 'found: Xvnc process'
		pgrep Xtightvnc && _messagePlain_warn 'found: Xtightvnc process'
		pgrep Xtigervnc && _messagePlain_warn 'found: Xtigervnc process'
		
		return 0
	fi
	
	_messagePlain_bad 'missing: usable "$vncPIDfile'
	_messagePlain_bad 'terminate: Xvnc, Xtightvnc, Xtigervnc'
	
	pkill Xvnc
	pkill Xtightvnc
	pkill Xtigervnc
	rm "$vncPIDfile"
	
	return 1
}

_vnc_sequence() {
	_messageNormal '_vnc_sequence: Start'
	_start
	_start_safeTmp_ssh "$@"
	_prepare_vnc
	
	_messageNormal '_vnc_sequence: Launch: _x11vnc'
	
	# TODO WARNING Terminal echo (ie. "stty echo") lockup errors are possible as ssh is backgrounded without "-f".
	cat "$vncPasswdFile".pln | _vnc_ssh -L "$vncPort":localhost:"$vncPort" "$@" 'env vncPort='"$vncPort"' '"$safeTmpSSH"/cautossh' _x11vnc' &
	
	_waitPort localhost "$vncPort"
	
	_messageNormal '_vnc_sequence: Ready: _waitPort localhost vncport= '"$vncPort"
	
	#VNC service may not always be ready when port is up.
	
	sleep 0.8
	if ! _checkPort localhost "$vncPort"
	then
		stty echo > /dev/null 2>&1
		_stop_safeTmp_ssh "$@"
		_stop
	fi
	_messageNormal '_vnc_sequence: Ready: sleep, _checkPort. Launch: _vncviewer'
	cat "$vncPasswdFile".pln | bash -c 'env vncPort='"$vncPort"' destination_DISPLAY='"$DISPLAY"' destination_AUTH="$XAUTHORITY"'"$scriptAbsoluteLocation"' _vncviewer'
	
	sleep 3
	if ! _checkPort localhost "$vncPort"
	then
		stty echo > /dev/null 2>&1
		_stop_safeTmp_ssh "$@"
		_stop
	fi
	_messageNormal '_vnc_sequence: Ready: sleep, _checkPort. Launch: _vncviewer'
	cat "$vncPasswdFile".pln | bash -c 'env vncPort='"$vncPort"' destination_DISPLAY='"$DISPLAY"' destination_AUTH="$XAUTHORITY"'"$scriptAbsoluteLocation"' _vncviewer'
	
	sleep 9
	if ! _checkPort localhost "$vncPort"
	then
		stty echo > /dev/null 2>&1
		_stop_safeTmp_ssh "$@"
		_stop
	fi
	_messageNormal '_vnc_sequence: Ready: sleep, _checkPort. Launch: _vncviewer'
	cat "$vncPasswdFile".pln | bash -c 'env vncPort='"$vncPort"' destination_DISPLAY='"$DISPLAY"' destination_AUTH="$XAUTHORITY"'"$scriptAbsoluteLocation"' _vncviewer'
	
	
	_messageNormal '_vnc_sequence: Done: final attempt: _vncviewer'
	
	_messageNormal '_vnc_sequence: Stop'
	stty echo > /dev/null 2>&1
	_stop_safeTmp_ssh "$@"
	_stop
}

_vnc() {
	"$scriptAbsoluteLocation" _vnc_sequence "$@"
}

_push_vnc_sequence() {
	_messageNormal '_push_vnc_sequence: Start'
	_start
	_start_safeTmp_ssh "$@"
	_prepare_vnc
	
	_messageNormal '_push_vnc_sequence: Launch: _x11vnc'
	
	cat "$vncPasswdFile".pln | bash -c 'env vncPort='"$vncPort"' '"$scriptAbsoluteLocation"' _x11vnc' &
	#-noxrecord -noxfixes -noxdamage
	
	_waitPort localhost "$vncPort"
	
	_messageNormal '_push_vnc_sequence: Ready: _waitPort localhost vncport= '"$vncPort"
	
	#VNC service may not always be ready when port is up.
	
	sleep 0.8
	if ! _checkPort localhost "$vncPort"
	then
		stty echo > /dev/null 2>&1
		_stop_safeTmp_ssh "$@"
		_stop
	fi
	_messageNormal '_push_vnc_sequence: Ready: sleep, _checkPort. Launch: _vncviewer'
	cat "$vncPasswdFile".pln | _vnc_ssh -R "$vncPort":localhost:"$vncPort" "$@" 'env vncPort='"$vncPort"' '"$safeTmpSSH"/cautossh' _vncviewer'
	
	sleep 3
	if ! _checkPort localhost "$vncPort"
	then
		stty echo > /dev/null 2>&1
		_stop_safeTmp_ssh "$@"
		_stop
	fi
	_messageNormal '_push_vnc_sequence: Ready: sleep, _checkPort. Launch: _vncviewer'
	cat "$vncPasswdFile".pln | _vnc_ssh -R "$vncPort":localhost:"$vncPort" "$@" 'env vncPort='"$vncPort"' '"$safeTmpSSH"/cautossh' _vncviewer'
	
	sleep 9
	if ! _checkPort localhost "$vncPort"
	then
		stty echo > /dev/null 2>&1
		_stop_safeTmp_ssh "$@"
		_stop
	fi
	_messageNormal '_push_vnc_sequence: Ready: sleep, _checkPort. Launch: _vncviewer'
	cat "$vncPasswdFile".pln | _vnc_ssh -R "$vncPort":localhost:"$vncPort" "$@" 'env vncPort='"$vncPort"' '"$safeTmpSSH"/cautossh' _vncviewer'
	
	_messageNormal '_push_vnc_sequence: Done: final attempt: _vncviewer'
	
	_messageNormal '_push_vnc_sequence: Stop'
	stty echo > /dev/null 2>&1
	_stop_safeTmp_ssh "$@"
	_stop 1
}

_push_vnc() {
	"$scriptAbsoluteLocation" _push_vnc_sequence "$@"
}

_desktop_sequence() {
	_messageNormal '_desktop_sequence: Start'
	_start
	_start_safeTmp_ssh "$@"
	_prepare_vnc
	
	_messageNormal '_vnc_sequence: Launch: _vncserver'
	# TODO WARNING Terminal echo (ie. "stty echo") lockup errors are possible as ssh is backgrounded without "-f".
	cat "$vncPasswdFile".pln | _vnc_ssh -L "$vncPort":localhost:"$vncPort" "$@" 'env vncPort='"$vncPort"' vncPIDfile='"$vncPIDfile"' desktopEnvironmentGeometry='"$desktopEnvironmentGeometry"' desktopEnvironmentLaunch='"$desktopEnvironmentLaunch"' '"$safeTmpSSH"/cautossh' _vncserver' &
	
	
	_waitPort localhost "$vncPort"
	sleep 0.8 #VNC service may not always be ready when port is up.
	
	_messageNormal '_vnc_sequence: Ready: _waitPort. Launch: _vncviewer'
	
	cat "$vncPasswdFile".pln | bash -c 'env vncPort='"$vncPort"' destination_DISPLAY='"$DISPLAY"' destination_AUTH="$XAUTHORITY"'"$scriptAbsoluteLocation"' _vncviewer'
	stty echo > /dev/null 2>&1
	
	_messageNormal '_vnc_sequence: Terminate: _vncserver_terminate'
	
	_vnc_ssh "$@" 'env vncPIDfile='"$vncPIDfile"' '"$safeTmpSSH"/cautossh' _vncserver_terminate'
	
	_messageNormal '_desktop_sequence: Stop'
	_stop_safeTmp_ssh "$@"
	_stop
}

#Launches VNC server and client, with up to nine nonpersistent desktop environments.
_desktop() {
	"$scriptAbsoluteLocation" _desktop_sequence "$@"
}

_push_desktop_sequence() {
	_messageNormal '_push_desktop_sequence: Start'
	_start
	_start_safeTmp_ssh "$@"
	_prepare_vnc
	
	_messageNormal '_push_desktop_sequence: Launch: _vncserver'
	cat "$vncPasswdFile".pln | bash -c 'env vncPort='"$vncPort"' vncPIDfile='"$vncPIDfile_local"' desktopEnvironmentGeometry='"$desktopEnvironmentGeometry"' desktopEnvironmentLaunch='"$desktopEnvironmentLaunch"' '"$scriptAbsoluteLocation"' _vncserver' &
	
	
	_waitPort localhost "$vncPort"
	sleep 0.8 #VNC service may not always be ready when port is up.
	
	_messageNormal '_push_desktop_sequence: Ready: _waitPort. Launch: _vncviewer'
	
	cat "$vncPasswdFile".pln | _vnc_ssh -R "$vncPort":localhost:"$vncPort" "$@" 'env vncPort='"$vncPort"' destination_DISPLAY='""' '"$safeTmpSSH"/cautossh' _vncviewer'
	stty echo > /dev/null 2>&1
	
	_messageNormal '_push_desktop_sequence: Terminate: _vncserver_terminate'
	
	bash -c 'env vncPIDfile='"$vncPIDfile_local"' '"$scriptAbsoluteLocation"' _vncserver_terminate'
	
	_messageNormal '_desktop_sequence: Stop'
	_stop_safeTmp_ssh "$@"
	_stop
}

_push_desktop() {
	"$scriptAbsoluteLocation" _push_desktop_sequence "$@"
}

#Builtin version of ssh-copy-id.
_ssh_copy_id() {
	_start
	
	"$scriptAbsoluteLocation" _ssh "$@" 'mkdir -p "$HOME"/.ssh'
	cat "$scriptLocal"/ssh/id_rsa.pub | "$scriptAbsoluteLocation" _ssh "$@" 'cat - >> "$HOME"/.ssh/authorized_keys'
	
	_stop
}
alias _ssh-copy-id=_ssh_copy_id

#"$1" == "key_name"
#"$2" == "local_subdirectory" (optional)
_setup_ssh_copyKey() {
	local sshKeyName
	local sshKeyLocalSubdirectory
	
	sshKeyName="$1"
	[[ "$2" != "" ]] && sshKeyLocalSubdirectory="$2"/
	
	if [[ -e "$scriptLocal"/ssh/"$sshKeyLocalSubdirectory""$sshKeyName" ]]
	then
		chmod 600 "$scriptLocal"/ssh/"$sshKeyLocalSubdirectory""$sshKeyName"
		chmod 600 "$scriptLocal"/ssh/"$sshKeyLocalSubdirectory""$sshKeyName".pub > /dev/null 2>&1
		
		cp -n "$scriptLocal"/ssh/"$sshKeyLocalSubdirectory""$sshKeyName" "$sshLocalSSH"/"$sshKeyName"
		cp -n "$scriptLocal"/ssh/"$sshKeyLocalSubdirectory""$sshKeyName".pub "$sshLocalSSH"/"$sshKeyName".pub > /dev/null 2>&1
		
		return 0
	fi
	
	if [[ -e "$scriptLocal"/ssh/"$sshKeyName" ]]
	then
		chmod 600 "$scriptLocal"/ssh/"$sshKeyName"
		chmod 600 "$scriptLocal"/ssh/"$sshKeyName".pub > /dev/null 2>&1
		
		cp -n "$scriptLocal"/ssh/"$sshKeyName" "$sshLocalSSH"/"$sshKeyName"
		cp -n "$scriptLocal"/ssh/"$sshKeyName".pub "$sshLocalSSH"/"$sshKeyName".pub > /dev/null 2>&1
		
		return 0
	fi
	
	return 1
}

#Overload with "ops".
_setup_ssh_extra() {
	true
}

_setup_ssh_merge_known_hosts() {
	[[ ! -e "$scriptLocal"/ssh/known_hosts ]] && echo > "$scriptLocal"/ssh/known_hosts
	[[ ! -e "$sshLocalSSH"/known_hosts ]] && echo > "$sshLocalSSH"/known_hosts
	sort "$scriptLocal"/ssh/known_hosts "$sshLocalSSH"/known_hosts | uniq > "$safeTmp"/known_hosts_uniq
	_cpDiff "$safeTmp"/known_hosts_uniq "$scriptLocal"/ssh/known_hosts
	
	_cpDiff "$scriptLocal"/ssh/known_hosts "$sshLocalSSH"/known_hosts
}

_setup_ssh_operations() {
	_prepare_ssh
	
	mkdir -p "$scriptLocal"/ssh
	
	! [[ -e "$sshBase" ]] && mkdir -p "$sshBase" && chmod 700 "$sshBase"
	! [[ -e "$sshBase"/"$ubiquitiousBashID" ]] && mkdir -p "$sshBase"/"$ubiquitiousBashID" && chmod 700 "$sshBase"/"$ubiquitiousBashID"
	! [[ -e "$sshDir" ]] && mkdir -p "$sshDir" && chmod 700 "$sshDir"
	! [[ -e "$sshLocal" ]] && mkdir -p "$sshLocal" && chmod 700 "$sshLocal"
	! [[ -e "$sshLocalSSH" ]] && mkdir -p "$sshLocalSSH" && chmod 700 "$sshLocalSSH"
	
	#! grep "$ubiquitiousBashID" "$sshBase"/config > /dev/null 2>&1 && echo 'Include "'"$sshUbiquitous"'/config"' >> "$sshBase"/config
	
	#Prepend include directive. Mitigates the risk of falling under an existing config directive (eg. Host/Match). Carries the relatively insignificant risk of a non-atomic operation.
	if ! grep "$ubiquitiousBashID" "$sshBase"/config > /dev/null 2>&1 && [[ ! -e "$sshBase"/config.tmp ]]
	then
		echo -n >> "$sshBase"/config
		echo 'Include "'"$sshUbiquitous"'/config"' >> "$sshBase"/config.tmp
		echo >> "$sshBase"/config.tmp
		cat "$sshBase"/config >> "$sshBase"/config.tmp
		mv "$sshBase"/config.tmp "$sshBase"/config
		
	fi
	
	! grep "$netName" "$sshUbiquitous"/config > /dev/null 2>&1 && echo 'Include "'"$sshDir"'/config"' >> "$sshBase"/config >> "$sshUbiquitous"/config
	
	if [[ "$keepKeys_SSH" == "false" ]]
	then
		rm -f "$scriptLocal"/ssh/id_rsa >/dev/null 2>&1
		rm -f "$scriptLocal"/ssh/id_rsa.pub >/dev/null 2>&1
		rm -f "$sshDir"/id_rsa >/dev/null 2>&1
		rm -f "$sshDir"/id_rsa.pub >/dev/null 2>&1
		rm -f "$sshLocalSSH"/id_rsa >/dev/null 2>&1
		rm -f "$sshLocalSSH"/id_rsa.pub >/dev/null 2>&1
	fi
	
	if ! [[ -e "$scriptLocal"/ssh/id_rsa ]] && ! [[ -e "$sshLocalSSH"/id_rsa ]]
	then
		ssh-keygen -b 4096 -t rsa -N "" -f "$scriptLocal"/ssh/id_rsa
	fi
	
	_here_ssh_config >> "$safeTmp"/config
	_cpDiff "$safeTmp"/config "$sshDir"/config
	
	_setup_ssh_copyKey id_rsa
	
	_setup_ssh_merge_known_hosts
	
	_cpDiff "$scriptAbsoluteLocation" "$sshDir"/cautossh
	
	# TODO Replace with a less oversimplified destination directory structure.
	#Concatenates all "ops" directives into one file to allow a single "cpDiff" operation.
	[[ -e "$objectDir"/ops ]] && cat "$objectDir"/ops >> "$safeTmp"/opsAll
	[[ -e "$scriptLocal"/ops ]] && cat "$scriptLocal"/ops >> "$safeTmp"/opsAll
	[[ -e "$scriptLocal"/ssh/ops ]] && cat "$scriptLocal"/ssh/ops >> "$safeTmp"/opsAll
	
	[[ -e "$objectDir"/opsauto ]] && cat "$objectDir"/opsauto >> "$safeTmp"/opsAll
	[[ -e "$scriptLocal"/opsauto ]] && cat "$scriptLocal"/opsauto >> "$safeTmp"/opsAll
	[[ -e "$scriptLocal"/ssh/opsauto ]] && cat "$scriptLocal"/ssh/opsauto >> "$safeTmp"/opsAll
	
	
	_cpDiff "$safeTmp"/opsAll "$sshLocalSSH"/ops
	
	_setup_ssh_extra
}

_setup_ssh_sequence() {
	_start
	
	_setup_ssh_operations
	
	_stop
}

_setup_ssh() {
	"$scriptAbsoluteLocation" _setup_ssh_sequence "$@"
}

_setup_ssh_commands() {
	find . -name '_ssh' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	find . -name '_rsync' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	
	find . -name '_web' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	
	find . -name '_backup' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	
	find . -name '_fs' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	
	find . -name '_vnc' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	find . -name '_push_vnc' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	find . -name '_desktop' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	find . -name '_push_desktop' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	
	find . -name '_wake' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
}

_package_cautossh() {
	#cp -a "$scriptAbsoluteFolder"/_index "$safeTmp"/package
	
	#https://stackoverflow.com/questions/4585929/how-to-use-cp-command-to-exclude-a-specific-directory
	#find "$scriptAbsoluteFolder"/_index -type f -not -path '*_arc*' -exec cp -d --preserve=all {} "$safeTmp"'/package/'{} \;
	
	rsync -av --progress --exclude "_arc" "$scriptAbsoluteFolder"/_index/ "$safeTmp"/package/_index/
}

#May be overridden by "ops" if multiple gateways are required.
_ssh_autoreverse() {
	_torServer_SSH
	_autossh
	
	#_autossh firstGateway
	#_autossh secondGateway
}
