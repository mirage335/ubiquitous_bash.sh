#Example, override with "core.sh" .
_scope_compile() {
	true
}

#Example, override with "core.sh" .
_scope_attach() {
	_messagePlain_nominal '_scope_attach'
	
	_scope_here > "$ub_scope"/.devenv
	_scope_readme_here > "$ub_scope"/README
	
	_scope_command_here _scope_compile
}

#Example, override with "core.sh" .
_scope_detach() {
	_messagePlain_nominal '_scope_detach'
}

_prepare_scope() {
	mkdir -p "$safeTmp"/scope
	#true
}

_relink_scope() {
	_relink "$safeTmp"/scope "$ub_scope"
	#_relink "$safeTmp" "$ub_scope"
	
	_relink "$safeTmp" "$ub_scope"/safeTmp
	_relink "$shortTmp" "$ub_scope"/shortTmp
}

_ops_scope() {
	_messagePlain_nominal '_ops_scope'
	
	#Find/run ops file in project dir.
	! [[ -e "$ub_specimen"/ops ]] && _messagePlain_warn 'aU: undef: sketch ops'
	[[ -e "$ub_specimen"/ops ]] && _messagePlain_good 'aU: found: sketch ops' && . "$ub_specimen"/ops
}

#"$1" == ub_specimen
#"$ub_scope_name" (default "scope")
# WARNING Multiple instances of same scope on a single specimen strictly forbidden. Launch multiple applications within a scope, not multiple scopes.
_start_scope() {
	_messagePlain_nominal '_start_scope'
	
	export ub_specimen=$(_getAbsoluteLocation "$1")
	export specimen="$ub_specimen"
	[[ ! -d "$ub_specimen" ]] && _messagePlain_bad 'missing: specimen= '"$ub_specimen" && _stop 1
	[[ ! -e "$ub_specimen" ]] && _messagePlain_bad 'missing: specimen= '"$ub_specimen" && _stop 1
	
	[[ "$ub_scope_name" == "" ]] && export ub_scope_name='scope'
	
	export ub_scope="$ub_specimen"/.s_"$ub_scope_name"
	export scope="$ub_scope"
	[[ -e "$ub_scope" ]] && _messagePlain_bad 'fail: safety: multiple scopes && single specimen' && _stop 1
	[[ -L "$ub_scope" ]] && _messagePlain_bad 'fail: safety: multiple scopes && single specimen' && _stop 1
	
	#export ub_scope_tmp="$ub_scope"/s_"$sessionid"
	
	_prepare_scope "$@"
	_relink_scope "$@"
	[[ ! -d "$ub_scope" ]] && _messagePlain_bad 'fail: link scope= '"$ub_scope" && _stop 1
	#[[ ! -d "$ub_scope_tmp" ]] && _messagePlain_bad 'fail: create ub_scope_tmp= '"$ub_scope_tmp" && _stop 1
	[[ ! -d "$ub_scope"/safeTmp ]] && _messagePlain_bad 'fail: link' && _stop 1
	[[ ! -d "$ub_scope"/shortTmp ]] && _messagePlain_bad 'fail: link' && _stop 1
	
	[[ ! -e "$ub_scope"/.pid ]] && echo $$ > "$ub_scope"/.pid
	
	_messagePlain_good 'pass: prepare, relink'
	
	return 0
}

_stop_scope() {
	_messagePlain_nominal '_stop_scope'
	
	rm "$ub_scope"
}

#Default, waits for kill signal, override with "core.sh" . May run file manager, terminal, etc.
# WARNING: Scope should only be terminated by process or user managing this interaction (eg. by closing file manager). Manager must be aware of any inter-scope dependencies.
_scope_interact() {
	_messagePlain_nominal '_stop_interact'
	while true ; do sleep 1 ; done
}


_scope_sequence() {
	export ub_scope_name='scope'
	_messagePlain_nominal 'init: scope: '"$ub_scope_name"
	_messagePlain_probe 'HOME= '"$HOME"
	
	_start
	_start_scope "$@"
	_ops_scope
	
	_scope_attach "$@"
	
	#User interaction.
	_scope_interact
	
	_scope_detach "$@"
	
	_stop_scope "$@"
	_stop
}

_scope() {
	"$scriptAbsoluteLocation" _scope_sequence "$@"
}