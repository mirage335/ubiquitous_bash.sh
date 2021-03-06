# # ATTENTION: Configure/Override .



# ATTENTION: Override .
_custom_set() {
	_messagePlain_nominal 'init: _custom_set'
	
	export custom_netName="$netName"
	export custom_hostname='hostname'
	
	export custom_user="user"
	[[ -e "$scriptLocal"/vm-raspbian.img ]] && export custom_user="pi"
	#export custom_user="username"
	
	export safeToDeleteGit="true"
}

# ATTENTION: Override (if necessary) .
_custom_prepare() {
	_messagePlain_nominal 'init: _custom_prepare'
	
	mkdir -p "$scriptLocal"/_custom
	
	rm -f "$scriptLocal"/_custom/* > /dev/null 2>&1
	
	
	! _openChRoot && _messageError 'FAIL: _openChRoot' && _stop 1
}

_custom_safety() {
	_messagePlain_nominal 'init: _custom_safety'
	
	export safeToDeleteGit="true"
	
	_messagePlain_probe 'custom_user= '"$custom_user"
	
	! _safePath "$scriptLib" && _messageError 'FAIL: _safePath: scriptLib' && _stop 1
	! _safePath "$scriptLocal" && _messageError 'FAIL: _safePath: scriptLocal' && _stop 1
	
	! _safePath "$globalVirtFS" && _messageError 'FAIL: _safePath: globalVirtFS' && _stop 1
	! _safePath "$globalVirtFS"/home/"$custom_user"/core/ && _messageError 'FAIL: _safePath: user' && _stop 1
}

# ATTENTION: Override (if necessary) .
# User-specific SSH identity will be taken from "$scriptLocal"/ssh_pub_[user]/*.pub (if available) .
_custom_users() {
	_custom_construct_user root
	echo 'root:password' | _chroot chpasswd
	
	_custom_construct_user "$custom_user"
	echo "$custom_user"':password' | _chroot chpasswd
	
	_custom_construct_user user1
	echo 'user1:password' | _chroot chpasswd
	_chroot usermod -s /bin/false user1
	
	_custom_construct_user user2
	echo 'user2:password' | _chroot chpasswd
	_chroot usermod -s /bin/false user2
}

# ATTENTION: Override (if necessary) .
_custom_users_ssh() {
	_custom_construct_user_ssh root
	_custom_construct_user_ssh "$custom_user"
	
	_custom_construct_user_ssh user1
	_custom_construct_user_ssh user2
}

_custom_packages_debian() {
	sudo -n rm -f "$globalVirtFS"/var/lib/apt/lists/lock
	sudo -n rm -f "$globalVirtFS"/var/lib/dpkg/lock
	
	sudo -n mkdir -p "$globalVirtFS"/etc/apt/sources.list.d
	echo 'deb http://deb.debian.org/debian buster-backports main contrib' | sudo -n tee "$globalVirtFS"/etc/apt/sources.list.d/custom_backports.list > /dev/null 2>&1
	
	sudo -n mkdir -p "$globalVirtFS"/etc/apt/sources.list.d
	echo 'deb http://download.virtualbox.org/virtualbox/debian buster contrib' | sudo -n tee "$globalVirtFS"/etc/apt/sources.list.d/vbox.list > /dev/null 2>&1
	
	_chroot wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | _chroot apt-key add -
	_chroot wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | _chroot apt-key add -
	
	_chroot apt-get update
	
	_chroot apt-get install -y sudo
	
	# DANGER: Requires expanded image!
	#_chroot apt-get upgrade -y
	
	if [[ -e "$scriptLib"/debian/packages/bup_0.29-3_amd64.deb ]]
	then
		sudo -n cp "$scriptLib"/debian/packages/bup_0.29-3_amd64.deb "$globalVirtFS"/
		_chroot dpkg -i /bup_0.29-3_amd64.deb
		_chroot rm -f /bup_0.29-3_amd64.deb
		_chroot apt-get install -y -f
	fi
	
	_chroot apt-get install -y bup
	
	_chroot apt-get install -y bc nmap autossh socat sshfs tor
	_chroot apt-get install -y sockstat
	_chroot apt-get install -y x11-xserver-utils
	
	_chroot apt-get install -y tigervnc-viewer
	_chroot apt-get install -y x11vnc
	_chroot apt-get install -y tigervnc-standalone-server
	
	#_chroot apt-get install -y synergy quicksynergy
	
	_chroot apt-get install -y vim
	
	if _chroot bash -c '! dpkg --print-foreign-architectures | grep i386'
	then
		_chroot dpkg --add-architecture i386
		_chroot apt-get update
	fi
	_chroot apt-get install -y wmctrl xprintidle okular libreoffice firefox-esr xournal kwrite netcat-openbsd iperf axel unionfs-fuse samba qemu qemu-system-x86 qemu-system-arm qemu-efi-arm qemu-efi-aarch64 qemu-user-static qemu-utils dosbox wine wine32 wine64 libwine libwine:i386 fonts-wine debootstrap xclip xinput gparted bup emacs xterm mesa-utils kde-standard
	_chroot apt-get install -y chromium
	_chroot apt-get install -y openjdk-11-jdk openjdk-11-jre
	
	# ATTENTION: ONLY uncomment if needed to ensure a kernel is installed AND custom kernel is not in use.
	_chroot apt-get install -y linux-image-amd64
	
	_chroot apt-get install -y net-tools wireless-tools rfkill
	
	
	# WARNING: Untested. May be old version of VirtualBox. May conflict with guest additions.
	#_chroot apt-get install -y virtualbox-6.1
	_chroot apt-get -d install -y virtualbox-6.1
	
	
	# WARNING: Untested. May cause problems.
	#_chroot apt-get install -y docker-ce
	_chroot apt-get -d install -y docker-ce
	
	
	# WARNING: Untested. May incorrectly remove supposedly 'old' kernel versions.
	#_chroot apt-get autoremove -y
	
	#sudo -n rm -f "$globalVirtFS"/ubtest.sh > /dev/null 2>&1
	#sudo -n cp "$scriptAbsoluteLocation" "$globalVirtFS"/ubtest.sh
	#_chroot /ubtest.sh _test
	
	_chroot apt-get install -y live-boot
	_chroot apt-get install -y pigz
	
	_chroot apt-get install -y falkon
	_chroot apt-get install -y konqueror
	
	_chroot apt-get install -y xserver-xorg-video-all
	
	_chroot apt-get install -y qalculate-gtk
	
	_chroot apt-get install -y octave
	_chroot apt-get install -y octave-arduino
	_chroot apt-get install -y octave-bart
	_chroot apt-get install -y octave-bim
	_chroot apt-get install -y octave-biosig
	_chroot apt-get install -y octave-bsltl
	_chroot apt-get install -y octave-cgi
	_chroot apt-get install -y octave-communications
	_chroot apt-get install -y octave-control
	_chroot apt-get install -y octave-data-smoothing
	_chroot apt-get install -y octave-dataframe
	_chroot apt-get install -y octave-dicom
	_chroot apt-get install -y octave-divand
	_chroot apt-get install -y octave-econometrics
	_chroot apt-get install -y octave-financial
	_chroot apt-get install -y octave-fits
	_chroot apt-get install -y octave-fuzzy-logic-toolkit
	_chroot apt-get install -y octave-ga
	_chroot apt-get install -y octave-gdf
	_chroot apt-get install -y octave-geometry
	_chroot apt-get install -y octave-gsl
	_chroot apt-get install -y octave-image
	_chroot apt-get install -y octave-image-acquisition
	_chroot apt-get install -y octave-instrument-control
	_chroot apt-get install -y octave-interval
	_chroot apt-get install -y octave-io
	_chroot apt-get install -y octave-level-set
	_chroot apt-get install -y octave-linear-algebra
	_chroot apt-get install -y octave-lssa
	_chroot apt-get install -y octave-ltfat
	_chroot apt-get install -y octave-mapping
	_chroot apt-get install -y octave-miscellaneous
	_chroot apt-get install -y octave-missing-functions
	_chroot apt-get install -y octave-mpi
	_chroot apt-get install -y octave-msh
	_chroot apt-get install -y octave-mvn
	_chroot apt-get install -y octave-nan
	_chroot apt-get install -y octave-ncarry
	_chroot apt-get install -y octave-netcdf
	_chroot apt-get install -y octave-nlopt
	_chroot apt-get install -y octave-nurbs
	_chroot apt-get install -y octave-octclip
	_chroot apt-get install -y octave-octproj
	_chroot apt-get install -y octave-openems
	_chroot apt-get install -y octave-optics
	_chroot apt-get install -y octave-optim
	_chroot apt-get install -y octave-optiminterp
	_chroot apt-get install -y octave-parallel
	_chroot apt-get install -y octave-pfstools
	_chroot apt-get install -y octave-plplot
	_chroot apt-get install -y octave-psychtoolbox-3
	_chroot apt-get install -y octave-quarternion
	_chroot apt-get install -y octave-queueing
	_chroot apt-get install -y octave-secs1d
	_chroot apt-get install -y octave-secs2d
	_chroot apt-get install -y octave-secs3d
	_chroot apt-get install -y octave-signal
	_chroot apt-get install -y octave-sockets
	_chroot apt-get install -y octave-sparsersb
	_chroot apt-get install -y octave-specfun
	_chroot apt-get install -y octave-splines
	_chroot apt-get install -y octave-stk
	_chroot apt-get install -y octave-strings
	_chroot apt-get install -y octave-struct
	_chroot apt-get install -y octave-symbolic
	_chroot apt-get install -y octave-tsa
	_chroot apt-get install -y octave-vibes
	_chroot apt-get install -y octave-vlfeat
	_chroot apt-get install -y octave-rml
	_chroot apt-get install -y octave-zenity
	_chroot apt-get install -y octave-zeromq
	
	
	_chroot apt-get install -y mktorrent
	
	_chroot apt-get install -y curl
	_chroot curl https://rclone.org/install.sh | _chroot bash -s beta
}

_custom_packages_gentoo() {
	true
	#return
	
	#emerge-webrsync
	#emerge --sync
	#emerge --oneshot portage
	#emerge --autounmask-write --changed-use --deep @world
	#etc-update --automode -5
	#emerge --changed-use --deep @world
	#emerge @preserved-rebuild
	
	_chroot env emerge --update gdb
	_chroot env emerge --update debugedit
	
	# WARNING: May or may not be a appropriate.
	_chroot env USE="-vlc" emerge --update --changed-use phonon phonon-gstreamer
	
	_chroot emerge --update nmap
	_chroot emerge --update wmctrl
	
	if ! sudo -n grep 'xprintidle' "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	then
		echo 'x11-misc/xprintidle ~amd64' | sudo -n tee -a "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	fi
	_chroot emerge --update xprintidle
	
	
	#return
	
	_chroot emerge --update okular
	_chroot emerge --update libreoffice
	
	# WARNING: May cause lengthy rebuild.
	#_chroot emerge --update --autounmask-write firefox
	#_chroot etc-update --automode -5
	#_chroot emerge --update firefox
	
	# WARNING: Chromium may attempt lengthy rebuild.
	#_chroot emerge --update --autounmask-write chromium
	#_chroot etc-update --automode -5
	#_chroot emerge --update chromium
	
	_chroot emerge --update xournal
	_chroot emerge --update kwrite
	
	_chroot emerge --update qalculate-gtk
	
	_chroot emerge --update octave
	
	_chroot emerge --update vlc
	
	
	#return
	
	_chroot emerge --update netcat
	_chroot emerge --update sshfs
	_chroot env USE=server emerge --update tigervnc
	
	_chroot emerge --update x11vnc
	_chroot emerge --update autossh
	_chroot emerge --update iperf
	_chroot emerge --update axel
	
	
	if ! sudo -n grep 'unionfs-fuse' "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	then
		echo 'sys-fs/unionfs-fuse ~amd64' | sudo -n tee -a "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	fi
	_chroot emerge --update unionfs-fuse
	
	_chroot emerge --update samba
	
	if ! sudo -n grep 'QEMU_SOFTMMU_TARGETS' "$globalVirtFS"/etc/portage/make.conf > /dev/null
	then
		echo 'QEMU_SOFTMMU_TARGETS="alpha aarch64 arm i386 mips mips64 mips64el mipsel ppc ppc64 s390x sh4 sh4eb sparc sparc64 x86_64"' | sudo -n tee -a "$globalVirtFS"/etc/portage/make.conf
	fi
	
	if ! sudo -n grep 'QEMU_USER_TARGETS' "$globalVirtFS"/etc/portage/make.conf > /dev/null
	then
		echo 'QEMU_USER_TARGETS="alpha aarch64 arm armeb i386 mips mipsel ppc ppc64 ppc64abi32 s390x sh4 sh4eb sparc sparc32plus sparc64"' | sudo -n tee -a "$globalVirtFS"/etc/portage/make.conf
	fi
	
	_chroot env USE=static-user emerge --update --autounmask-write app-emulation/qemu
	_chroot etc-update --automode -5
	_chroot env USE=static-user emerge --update app-emulation/qemu
	
	# https://wiki.gentoo.org/wiki/Embedded_Handbook/General/Compiling_with_qemu_user_chroot
	echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-aarch64:' | sudo -n tee "$globalVirtFS"/etc/binfmt.d/qemu-aarch64-static.conf > /dev/null
	echo ':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm:' | sudo -n tee "$globalVirtFS"/etc/binfmt.d/qemu-arm-static.conf > /dev/null
	echo ':armeb:M::\x7fELF\x01\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-armeb:' | sudo -n tee "$globalVirtFS"/etc/binfmt.d/qemu-armeb-static.conf > /dev/null
	
	_chroot systemctl enable systemd-binfmt
	
	
	# WARNING:May slow down virtualized guest startup/shutdown.
	# May be necessary to pass full ubiquitous_bash "_test" procedure.
	#_chroot emerge --update virtualbox
	
	
	_chroot emerge --update dosbox
	
	# https://forums.gentoo.org/viewtopic-t-1062884-start-0.html
	_chroot emerge --update --autounmask-write wine
	_chroot etc-update --automode -5
	_chroot env USE=-gpm emerge --update wine
	
	
	_chroot env USE=cgroup-hybrid emerge --changed-use --update sys-apps/systemd
	# WARNING:May slow down virtualized guest startup/shutdown.
	# May be necessary to pass full ubiquitous_bash "_test" procedure.
	#_chroot emerge --update app-emulation/docker
	#_chroot systemctl enable docker
	
	# https://wiki.gentoo.org/wiki/Docker#Docker_service_runs_but_fails_to_start_container_.28systemd.29
	_messagePlain_request 'request: boot parameters: systemd.legacy_systemd_cgroup_controller=yes systemd.unified_cgroup_hierarchy=0' | tee -a "$scriptLocal"/_custom/requestLog
	_messagePlain_request 'request: grub-mkconfig -o /boot/grub/grub.cfg' | tee -a "$scriptLocal"/_custom/requestLog
	
	
	_chroot emerge --update debootstrap
	
	_chroot emerge --update x11-misc/xclip
	_chroot emerge --update xinput
	
	_chroot emerge --update gparted
	
	
	if ! sudo -n grep 'bup' "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	then
		echo 'app-backup/bup ~amd64' | sudo -n tee -a "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	fi
	_chroot emerge --update bup
	
	#if ! sudo -n grep 'atom' "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	#then
	#	echo 'app-editors/atom ~amd64' | sudo -n tee -a "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	#fi
	#if ! sudo -n grep 'electron' "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	#then
	#	echo 'dev-util/electron ~amd64' | sudo -n tee -a "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	#fi
	#if ! sudo -n grep 'eselect-electron' "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	#then
	#	echo 'app-eselect/eselect-electron ~amd64' | sudo -n tee -a "$globalVirtFS"/etc/portage/package.accept_keywords > /dev/null
	#fi
	#_chroot emerge --update --autounmask-write app-editors/atom
	#_chroot etc-update --automode -5
	#_chroot emerge --update app-editors/atom
	
	# https://forums.gentoo.org/viewtopic-t-1077066-start-0.html
	_chroot emerge --update synergy
	_chroot emerge --update quicksynergy
	
	_chroot emerge --update emacs
	
	_chroot emerge --update xterm
	_chroot emerge --update mesa
	
	# Alternatively disable KDE bluetooth integration.
	# https://wiki.gentoo.org/wiki/KDE/Troubleshooting
	_chroot systemctl enable bluetooth
	
	_chroot emerge @preserved-rebuild
}

# ATTENTION: Override (if necessary) .
_custom_packages() {
	true
	
	_custom_packages_debian "$@"
	
	#_custom_packages_gentoo "$@"
}

# ATTENTION: Override (if necessary) .
_custom_copy_directory() {
	true
	#_custom_rsync "$scriptLib"/'directory'/ "$globalVirtFS"/home/pi/core/'directory'/
}

# ATTENTION: Override (if necessary) .
_custom_prog() {
	true
	
	# ATTENTION: Some of these commands may fail. This is normal.
	_chroot usermod -a -G sudo "$custom_user"
	_chroot usermod -a -G wheel "$custom_user"
	_chroot usermod -a -G wireshark "$custom_user"
	
	_chroot usermod -a -G cdrom "$custom_user"
	_chroot usermod -a -G floppy "$custom_user"
	_chroot usermod -a -G audio "$custom_user"
	_chroot usermod -a -G dip "$custom_user"
	_chroot usermod -a -G video "$custom_user"
	_chroot usermod -a -G plugdev "$custom_user"
	_chroot usermod -a -G netdev "$custom_user"
	_chroot usermod -a -G bluetooth "$custom_user"
	_chroot usermod -a -G lpadmin "$custom_user"
	_chroot usermod -a -G scanner "$custom_user"
	
	_chroot usermod -a -G disk "$custom_user"
	_chroot usermod -a -G dialout "$custom_user"
	_chroot usermod -a -G lpadmin "$custom_user"
	_chroot usermod -a -G scanner "$custom_user"
	_chroot usermod -a -G vboxusers "$custom_user"
	_chroot usermod -a -G libvirt "$custom_user"
	_chroot usermod -a -G docker "$custom_user"
	
	
	sudo -n mkdir -p "$globalVirtFS"/boot/efi/EFI/BOOT/
	sudo -n cp "$globalVirtFS"/boot/efi/EFI/debian/grubx64.efi "$globalVirtFS"/boot/efi/EFI/BOOT/bootx64.efi
	
	_custom_cautossh
	
	_tryExec _custom_cautossh-limited
}

# ATTENTION: REVISE AS NECESSARY .
_custom() {
	_messageNormal '_custom: SET , PREPARE, SAFETY'
	_custom_set
	_custom_prepare
	_custom_safety
	
	_messageNormal '_custom: ...'
	
	_custom_users
	_custom_users_ssh
	
	
	_custom_packages
	
	_custom_copy_directory
	_custom_prog
	
	_custom_construct_crontab
	_custom_write_fs
	
	# Guarantee permissions, inclusions, etc.
	_custom_users
	_custom_users_ssh
	
	_messagePlain_nominal '_custom: requestLog'
	#_messagePlain_request 'request: request' | tee -a "$scriptLocal"/_custom/requestLog
	cat "$scriptLocal"/_custom/requestLog 2> /dev/null
	 _messageNormal '_custom: END'
}




