" GENERATED from colors.yaml by scripts/colors/render.sh. Edit the yaml, not this file.
" Sourced by .vimrc (runtime colors.vim).  Re-applied on ColorScheme, which clears
" every group, and on VimEnter, after plugins have defined their own defaults.

function! s:apply() abort
  " -- core
  highlight LineNr ctermfg=4 ctermbg=0
  " matches tmux's mode-style
  highlight Visual ctermfg=15 ctermbg=4
  " line, column and the %= fill: the main readout
  highlight User1 ctermfg=15 ctermbg=236 cterm=bold
  " modified [+], /total, 0xchar: [+] has to stand out
  highlight User2 ctermfg=6 ctermbg=236
  " filetype
  highlight User3 ctermfg=2 ctermbg=236
  " full path; yellow like the prompt's path
  highlight User4 ctermfg=3 ctermbg=236 cterm=bold
  " line endings: rarely interesting, so dimmed
  highlight User5 ctermfg=8 ctermbg=236
  " diagnostics: syntastic flag and LSP [E:n W:n]
  highlight User6 ctermfg=9 ctermbg=236 cterm=bold
endfunction

call s:apply()
augroup dotfiles_colors
  autocmd!
  autocmd ColorScheme,VimEnter * call s:apply()
augroup END
