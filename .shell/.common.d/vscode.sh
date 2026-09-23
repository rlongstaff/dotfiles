
export PATH="${PATH}:/Applications/Development/Visual\ Studio\ Code.app/Contents/Resources/app/bin"

# VSCODE must be set elsewhere (e.g. .dotfilesrc) to the code binary path.
function vsc {
  if (( $# )); then
    "$VSCODE" "$@"
  else
    "$VSCODE" .
  fi
}

alias vsca="$VSCODE --add"
alias vscd="$VSCODE --diff"
alias vscg="$VSCODE --goto"
alias vscn="$VSCODE --new-window"
alias vscr="$VSCODE --reuse-window"
