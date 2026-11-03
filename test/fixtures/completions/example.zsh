[0m[10000D[49m[39m#compdef prompt
local line

_arguments -C \
	"--help[Show help information]" \
	"--version[Show version information]" \
	"--completion[Generate completion script]:shell_name:->shell_names" \
	"1: :((fail\:'' test\:'' \:'' ))" \ 
	"*::arg:->args"

case "$state" in
	shell_names)
		_values 'shell_names' zsh bash fish
	;;
esac

case $line[1] in
  	fail)
		_prompt_fail
	;;
	test)
		_prompt_test
	;;
 
esac

function _prompt_fail {
	_arguments \
		 
}

function _prompt_test {
	_arguments \
		"--help[]"  
}


[0m
[0m