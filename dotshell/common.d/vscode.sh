
export PATH="${PATH}:/Applications/Development/Visual\ Studio\ Code.app/Contents/Resources/app/bin"

function vsc {
  if (( $# )); then
    $VSCODE $@
  else
    $VSCODE .
  fi
}

alias vsca="$VSCODE --add"
alias vscd="$VSCODE --diff"
alias vscg="$VSCODE --goto"
alias vscn="$VSCODE --new-window"
alias vscr="$VSCODE --reuse-window"
