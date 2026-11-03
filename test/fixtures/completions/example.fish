complete -c prompt -l help -d 'Show help information'
complete -c prompt -l version -d 'Show version information'
complete -c prompt -l completion -x -a 'zsh bash fish' -d 'Generate completion script'
complete -c prompt -n '__fish_use_subcommand' -a fail
complete -c prompt -n '__fish_use_subcommand' -a test
complete -c prompt -n '__fish_seen_subcommand_from test' -l help
