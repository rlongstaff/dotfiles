_gh_complete() {
  local dir="$WORKSPACE_DIR"
	_values 'workspace' $(ls "$dir")
}

compdef _gh_complete gh
