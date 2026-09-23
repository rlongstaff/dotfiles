# Google Cloud SDK: PATH and completion from the SDK's own .inc files.  First install found
# wins: personal checkout, then the Homebrew, apt/rpm, snap and /opt locations.

if [ -n "$ZSH_VERSION" ]; then
    _gc_shell=zsh
else
    _gc_shell=bash
fi

for _gc_dir in \
    "${CLOUDSDK_HOME}" \
    "${HOME}/prj/google-cloud-sdk" \
    "${HOME}/google-cloud-sdk" \
    /opt/homebrew/share/google-cloud-sdk \
    /usr/local/share/google-cloud-sdk \
    /usr/share/google-cloud-sdk \
    /usr/lib/google-cloud-sdk \
    /usr/lib64/google-cloud-sdk \
    /snap/google-cloud-cli/current \
    /snap/google-cloud-sdk/current \
    /opt/google-cloud-cli \
    /opt/google-cloud-sdk; do
    if [ -n "$_gc_dir" ] && [ -f "${_gc_dir}/completion.${_gc_shell}.inc" ]; then
        [ -f "${_gc_dir}/path.${_gc_shell}.inc" ] && . "${_gc_dir}/path.${_gc_shell}.inc"
        . "${_gc_dir}/completion.${_gc_shell}.inc"
        break
    fi
done
unset _gc_dir _gc_shell
