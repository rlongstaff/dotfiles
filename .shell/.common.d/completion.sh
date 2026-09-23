# Completion for CLIs that generate their own (`<tool> completion bash|zsh`).
#
# Each tool's script is cached under ~/.cache/dotfiles/completion/<shell>/ and only
# regenerated when the binary is newer than the cache, so a normal shell start costs one
# timestamp test per tool instead of one fork per tool.  Sourcing a file rather than
# `source <(...)` keeps the bash path bash 3.x safe.
#
# Defined here, called by .bashrc / .zshrc after the loader: PATH is only complete once
# every module (homebrew.sh, golang.sh, ...) has run.  zsh also needs compinit first.

dotfiles_completion() {
  case $- in
    *i*) ;;
    *) return 0 ;;
  esac
  _dc_shell=bash
  [ -n "$ZSH_VERSION" ] && _dc_shell=zsh
  if [ "$_dc_shell" = zsh ] && ! whence compdef >/dev/null 2>&1; then
    return 0
  fi

  _dc_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/completion/${_dc_shell}"
  for _dc_tool in docker kubectl helm minikube eksctl; do
    _dc_bin=$(command -v "$_dc_tool" 2>/dev/null)
    case "$_dc_bin" in
      /*) ;;
      *) continue ;;
    esac
    _dc_file="${_dc_dir}/${_dc_tool}"
    if [ ! -s "$_dc_file" ] || [ "$_dc_bin" -nt "$_dc_file" ]; then
      mkdir -p "$_dc_dir" 2>/dev/null || continue
      # Temp file then mv: a failed or empty generation never replaces a good cache, and
      # two shells starting at once never read a half-written file.
      if "$_dc_bin" completion "$_dc_shell" > "${_dc_file}.$$" 2>/dev/null \
          && [ -s "${_dc_file}.$$" ]; then
        mv -f "${_dc_file}.$$" "$_dc_file"
      else
        rm -f "${_dc_file}.$$"
      fi
    fi
    [ -s "$_dc_file" ] && . "$_dc_file"
  done

  # kn is kubectl (kube.sh)
  if command -v kubectl >/dev/null 2>&1; then
    if [ "$_dc_shell" = zsh ]; then
      compdef kn=kubectl
    else
      complete -o default -F __start_kubectl kn
    fi
  fi

  unset _dc_shell _dc_dir _dc_tool _dc_bin _dc_file
}
