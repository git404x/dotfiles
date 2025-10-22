if status is-interactive
    # Commands to run in interactive sessions can go here
end

# init Starship shell
starship init fish | source

# Helpful aliases
abbr c 'clear' # clear terminal
abbr l 'eza -lh  --icons=auto' # long list
abbr ls 'eza -1   --icons=auto' # short list
abbr ll 'eza -lha --icons=auto --sort=name --group-directories-first' # long list all
abbr ld 'eza -lhD --icons=auto' # long list dirs

# Handy change dir shortcuts
abbr '..' 'cd ..'
abbr '...' 'cd ../..'
abbr '.3' 'cd ../../..'
abbr '.4' 'cd ../../../..'
abbr '.5' 'cd ../../../../..'

# others
abbr info 'fastfetch'
abbr fetch 'fastfetch'
abbr neofetch 'fastfetch'
