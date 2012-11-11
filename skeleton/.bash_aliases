alias df='df -h'
alias du='du -hs'
alias p='pv -cN'
alias ls='ls --color=auto -h'
alias ack='ack-grep'

# not an alias but let's keep it here:
PROMPT_COMMAND="$PROMPT_COMMAND${PROMPT_COMMAND+;}history -a; history -n"
