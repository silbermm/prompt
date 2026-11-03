[0m[10000D[49m[39m#compdef prompt
local line

_arguments -C \
	"--help[Show help information]" \
	"--version[Show version information]" \
	"--completion[Generate completion script]:shell_name:->shell_names" \
	"1: :((\:'' test\:'' fail\:'' ))" \ 
	"*::arg:->args"

case "$state" in
	shell_names)
		_values 'shell_names' zsh bash fish
	;;
esac

case $line[1] in
  	test)
		_prompt_test
	;;
	fail)
		_prompt_fail
	;;
 
esac

function _prompt_test {
	_arguments \
		"--help[]"  
}

function _prompt_fail {
	_arguments \
		 
}


[0m
[0m