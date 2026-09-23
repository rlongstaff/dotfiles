" Go: gofmt's layout.  vim's own ftplugin/go.vim already sets noexpandtab and
" shiftwidth=0 (follow 'tabstop'), which would leave Go indented with the global 2-column
" tabs from .vimrc.  Buffer-local, no plugin calls; the language server (if any) adds
" format-on-save and 'tagfunc' in vimide#lsp_setup.
setlocal noexpandtab
setlocal tabstop=4
setlocal shiftwidth=0
setlocal softtabstop=0
setlocal textwidth=0

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . ' | setlocal et< ts< sw< sts< tw<'
