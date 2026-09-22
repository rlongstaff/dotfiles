_gh_complete() {
  local dir="$WORKSPACE_DIR"
  COMPREPLY=($(compgen -W "$(ls "$dir")" -- "${COMP_WORDS[1]}"))
}
complete -F _gh_complete gh
