
source .bash/.bash_profile

if [ -e "${HOME}/.iterm2_shell_integration.bash" ]; then
    source "${HOME}/.iterm2_shell_integration.bash"
elif [ ${LC_TERMINAL} -eq "iTerm2" ]; then
    echo "iTerm2 shell integration not found. Please install it from iTerm2 preferences."
fi
