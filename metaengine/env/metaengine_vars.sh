_set_me_host() {
	export metaTmp="$scriptAbsoluteFolder""$tmpPrefix"/.m_"$sessionid"
}

_set_me() {
	_messagePlain_nominal 'init: _set_me'
	
	_set_me_base
	#_set_me_objname
	
	_set_me_uid
	
	_set_me_path
	_set_me_dir
	_set_me_reg
	
	_set_me_io
	
	_message_me_set
}

_reset_me() {
	_reset_me_base
	#_reset_me_objname
	
	_reset_me_uid
	
	_reset_me_path
	_reset_me_dir
	_reset_me_reg
	
	_reset_me_name
	_reset_me_coordinates
	
	_reset_me_type
	
	_reset_me_io
	
	_stop_metaengine_allow
}

_set_me_uid() {
	export metaID=$(_uid)
}

_reset_me_uid() {
	export metaID=
}

_set_me_path() {
	export metaPath="$metaID"
}

_reset_me_path() {
	export metaPath=
}

_set_me_dir() {
	export metaDir_tmp="$metaTmp"/"$metaPath"
	export metaDir_base="$metaBase"/"$metaPath"
	
	export metaDir="$metaDir_tmp"
	[[ "$metaType" == "base" ]] && export metaDir="$metaDir_base" && _messagePlain_warn 'metaType= base'
	[[ "$metaType" == "" ]] && _messagePlain_good 'metaType= '
}

_reset_me_dir() {
	export metaDir_tmp=
	export metaDir_base=
	
	export metaDir=
}

_set_me_reg() {
	export metaReg="$metaTmp"/_reg
	[[ "$metaType" == "base" ]] && export metaReg="$metaBase"/_reg
}

_reset_me_reg() {
	export metaReg=
}




# ATTENTION: Overload with "core.sh" if appropriate.
_set_me_base() {
	export metaBase=
	
	export metaBase="$outerPWD"
	
	#[[ "$@" != "" ]] && export metaengine_base=$(_searchBaseDir "$@")
	#[[ "$metaengine_base" == "" ]] && export metaengine_base=$(_searchBaseDir "$@" "$virtUserPWD")
	
	#export metaengine_base="$scriptAbsoluteLocation"
}

_reset_me_base() {
	export metaBase=
}

# ATTENTION: Overload with "core.sh" if appropriate.
# WARNING: No production use.
_set_me_objname() {
	export metaObjName=
	
	export metaObjName="$objectName"
}

_reset_me_objname() {
	export metaObjName=
}



_reset_me_coordinates_ai() {
	export in_me_a_x=
	export in_me_a_y=
	export in_me_a_z=
}

_reset_me_coordinates_bi() {
	export in_me_b_x=
	export in_me_b_y=
	export in_me_b_z=
}

_reset_me_coordinates_ao() {
	export out_me_a_x=
	export out_me_a_y=
	export out_me_a_z=
}

_reset_me_coordinates_bo() {
	export out_me_b_x=
	export out_me_b_y=
	export out_me_b_z=
}

_reset_me_coordinates() {
	_reset_me_coordinates_ai
	_reset_me_coordinates_bi
	_reset_me_coordinates_ao
	_reset_me_coordinates_bo
}


_check_me_coordinates_ai() {
	[[ "$in_me_a_x" == "" ]] && return 1
	[[ "$in_me_a_y" == "" ]] && return 1
	[[ "$in_me_a_z" == "" ]] && return 1
	return 0
}

_check_me_coordinates_bi() {
	[[ "$in_me_b_x" == "" ]] && return 1
	[[ "$in_me_b_y" == "" ]] && return 1
	[[ "$in_me_b_z" == "" ]] && return 1
	return 0
}

_check_me_coordinates_ao() {
	[[ "$out_me_a_x" == "" ]] && return 1
	[[ "$out_me_a_y" == "" ]] && return 1
	[[ "$out_me_a_z" == "" ]] && return 1
	return 0
}

_check_me_coordinates_bo() {
	[[ "$out_me_b_x" == "" ]] && return 1
	[[ "$out_me_b_y" == "" ]] && return 1
	[[ "$out_me_b_z" == "" ]] && return 1
	return 0
}

_check_me_coordinates() {
	! _check_me_coordinates_ai && return 1
	! _check_me_coordinates_bi && return 1
	! _check_me_coordinates_ao && return 1
	! _check_me_coordinates_bo && return 1
	return 0
}

_reset_me_name_ai() {
	export in_me_a_name=
}

_reset_me_name_bi() {
	export in_me_b_name=
}

_reset_me_name_ao() {
	export out_me_a_name=
}

_reset_me_name_bo() {
	export out_me_b_name=
}

_reset_me_rand() {
	_reset_me_name_ai
	_reset_me_name_bi
	_reset_me_name_ao
	_reset_me_name_bo
}
_reset_me_name() {
	_reset_me_name_ai
	_reset_me_name_bi
	_reset_me_name_ao
	_reset_me_name_bo
}

_check_me_name() {
	[[ "$in_me_a_name" == "" ]] && return 1
	[[ "$in_me_b_name" == "" ]] && return 1
	[[ "$out_me_a_name" == "" ]] && return 1
	[[ "$out_me_b_name" == "" ]] && return 1
	return 0
}
_check_me_rand() {
	_check_me_name
}

_set_me_io_name() {
	_messagePlain_nominal 'init: _set_me_io_name'
	
	export in_me_a_path="$metaReg"/name/"$in_me_a_name"/ai
		[[ "$in_me_a_name" == "null" ]] && export in_me_a_path=/dev/null
	export in_me_b_path="$metaReg"/name/"$in_me_b_name"/bi
		[[ "$in_me_b_name" == "null" ]] && export in_me_b_path=/dev/null
	export out_me_a_path="$metaReg"/name/"$out_me_a_name"/ao
		[[ "$out_me_a_name" == "null" ]] && export out_me_a_path=/dev/null
	export out_me_b_path="$metaReg"/name/"$out_me_b_name"/bo
		[[ "$out_me_b_name" == "null" ]] && export out_me_b_path=/dev/null
	
	_messagePlain_good 'return: success'
	return 0
}

_set_me_io_coordinates() {
	_messagePlain_nominal 'init: _set_me_io_coordinates'
	
	export in_me_a_path="$metaReg"/grid/"$in_me_a_z"/"$in_me_a_x"/"$in_me_a_y"
	export in_me_b_path="$metaReg"/grid/"$in_me_b_z"/"$in_me_b_x"/"$in_me_b_y"
	export out_me_a_path="$metaReg"/grid/"$out_me_a_z"/"$out_me_a_x"/"$out_me_a_y"
	export out_me_b_path="$metaReg"/grid/"$out_me_b_z"/"$out_me_b_x"/"$out_me_b_y"
	
	_messagePlain_good 'return: success'
	return 0
}

_set_me_io() {
	_messagePlain_nominal 'init: _set_me_io'
	
	! _check_me_coordinates && ! _check_me_name && _messageError 'FAIL: invalid IO coordinates and names' && return 1
	
	_check_me_name && _messagePlain_good 'valid: name' && _set_me_io_name && _messagePlain_good 'return: success' && return 0
	
	_check_me_coordinates && _messagePlain_good 'valid: coordinates' && _set_me_io_coordinates && _messagePlain_good 'return: success' && return 0
	
	_messagePlain_warn 'return: undefined failure'
	return 1
}

_reset_me_io() {
	export in_me_a_path=
	export in_me_b_path=
	export out_me_a_path=
	export out_me_b_path=
}
