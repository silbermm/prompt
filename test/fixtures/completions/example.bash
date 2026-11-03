_prompt() {
	local cur prev cmd
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	cmd="${COMP_WORDS[1]}"

	if [ "$prev" = "--completion" ]; then
		COMPREPLY=( $(compgen -W "zsh bash fish" -- "$cur") )
		return
	fi

	if [ "$COMP_CWORD" -eq 1 ]; then
		COMPREPLY=( $(compgen -W "test fail --help --version --completion" -- "$cur") )
		return
	fi

	case "$cmd" in
		test)
			COMPREPLY=( $(compgen -W "--help" -- "$cur") )
			;;
		fail)
			COMPREPLY=( $(compgen -W "" -- "$cur") )
			;;
	esac
}

complete -F _prompt prompt
