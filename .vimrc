" vim.  Plain vim first: everything here works with no plugins, no language servers and
" nothing installed.  Key bindings are in .vim/keys.vim, GENERATED from
" scripts/keyboard/keys.yaml by scripts/keyboard/render.sh; the functions they call are in
" .vim/autoload/vimide.vim.

" Must come first, and must be explicit: started as `vim -u .vimrc`, vim leaves
" 'compatible' on, and pathogen.vim then silently defines nothing (it bails on &cp).
set nocompatible

" The .vim directory next to this file, wherever it was loaded from.  Installed, ~/.vim
" already is that directory (a symlink); `vim -u .vimrc` in the checkout, or a different
" $HOME, would otherwise never see keys.vim or the autoload functions.
let s:vimdir = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/.vim'
if isdirectory(s:vimdir)
      \ && index(map(split(&runtimepath, ','),
      \              'resolve(fnamemodify(expand(v:val), ":p:h"))'), s:vimdir) < 0
  let &runtimepath = s:vimdir . ',' . &runtimepath
endif

" Plugins load first, so 'runtimepath' is complete before anything below uses it.
" Guarded: no pathogen, no plugins, no error.
if !empty(globpath(&runtimepath, 'autoload/pathogen.vim'))
  execute pathogen#infect()
endif

" -- editing ---------------------------------------------------------------------------
set textwidth=100
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set smarttab
set autoindent
set smartindent
set wrap
set backspace=eol,start,indent

" -- display ---------------------------------------------------------------------------
set ruler
set number
set numberwidth=5
set hlsearch
set showmatch
syntax enable

" -- mouse -----------------------------------------------------------------------------
" 'sgr' rather than the 'xterm' vim picks under TERM=tmux-256color: no column-223 limit,
" and drag is told apart from move.  Every terminal on the target list speaks it.
set mouse=a
if has('mouse_sgr')
  set ttymouse=sgr
endif

" -- terminal input --------------------------------------------------------------------
" Alt arrives as ESC + key.  ttimeoutlen keeps a bare Escape responsive while leaving time
" for the second byte.  keys.vim declares the Alt+letter keys themselves.
if !has('gui_running')
  set ttimeout
  set ttimeoutlen=25
endif

" -- clipboard -------------------------------------------------------------------------
" Every yank (not delete or change) also goes to the system clipboard when a clipboard
" tool is installed; see vimide#clip.  Set g:vimide_clipboard = 0 to turn it off.
" Paste needs nothing: bracketed paste comes from terminfo, and 'paste' would disable it.
if exists('##TextYankPost') && !empty(globpath(&runtimepath, 'autoload/vimide.vim'))
  augroup vimide_clipboard
    autocmd!
    autocmd TextYankPost *
          \ if v:event.operator ==# 'y' |
          \   call vimide#clip(join(v:event.regcontents, "\n")
          \        . (v:event.regtype ==# 'V' ? "\n" : '')) |
          \ endif
  augroup END
endif

" -- colours ---------------------------------------------------------------------------
" Selection matches tmux's mode-style.  Numbers, not names: vim's 'Blue' is colour12 and
" tmux's 'blue' is colour4.
highlight Visual ctermbg=4 ctermfg=15
highlight LineNr ctermbg=black ctermfg=darkblue

" -- plugins (all optional) ------------------------------------------------------------
" A plain `let g:` never errors, so settings need no guard; commands do.
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:NERDTreeShowHidden = 1
augroup vimide_nerdtree
  autocmd!
  autocmd VimEnter * if exists(':NERDTree') | NERDTree | wincmd p | endif
  " Close the tab if NERDTree is the only window left in it.
  autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree()
        \ | call feedkeys(":quit\<CR>:\<BS>") | endif
augroup END

" -- statusline ------------------------------------------------------------------------
set laststatus=2
set statusline=
set statusline +=%5*[%{&ff}]%*          "file format
set statusline +=%3*%y%*                "file type
set statusline +=%4*\ %<%F%*            "full path
" Guarded inline: the statusline is re-evaluated on every redraw, so an unguarded
" SyntasticStatuslineFlag() without syntastic is an E117 per keystroke.
set statusline +=%#warningmsg#
set statusline +=%{exists('*SyntasticStatuslineFlag')?SyntasticStatuslineFlag():''}
set statusline +=%*
set statusline +=%2*%m%*                "modified flag
set statusline +=%1*%=%5l%*             "current line
set statusline +=%2*/%L%*               "total lines
set statusline +=%1*%4c\ %*             "column number
set statusline +=%2*0x%04B\ %*          "character under cursor

" -- keys ------------------------------------------------------------------------------
runtime keys.vim
