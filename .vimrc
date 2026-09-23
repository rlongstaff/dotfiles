" vim.  Plain vim first: everything here works with no plugins, no language servers and
" nothing installed.  Key bindings are in .vim/keys.vim, GENERATED from keys.yaml (repo
" root) by scripts/keyboard/render.sh; the functions they call are in
" .vim/autoload/vimide.vim.

" Must come first, and must be explicit: started as `vim -u .vimrc`, vim leaves
" 'compatible' on, and pathogen.vim then silently defines nothing (it bails on &cp).
set nocompatible

" Modelines are a known code-execution vector, and keys.yaml has literal "vim: {...}" text
" near its end (the per-key vim binding field) that vim's modeline scanner misreads as a
" `vim:` modeline, erroring on "{modes" as an unknown option.
set nomodeline

" The .vim directory next to this file, wherever it was loaded from.  Installed, ~/.vim
" already is that directory (a symlink); `vim -u .vimrc` in the checkout, or a different
" $HOME, would otherwise never see keys.vim or the autoload functions.
let s:vimdir = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/.vim'
if isdirectory(s:vimdir)
      \ && index(map(split(&runtimepath, ','),
      \              'resolve(fnamemodify(expand(v:val), ":p:h"))'), s:vimdir) < 0
  let &runtimepath = s:vimdir . ',' . &runtimepath . ',' . s:vimdir . '/after'
endif

" Plugins load first, so 'runtimepath' is complete before anything below uses it.
" Guarded: no pathogen, no plugins, no error.  A bundle this vim cannot run is never
" loaded: lsp is vim9script (it also guards itself), and vimspector needs +python3 and
" would otherwise warn on every start.
let g:pathogen_disabled = get(g:, 'pathogen_disabled', [])
if v:version < 900 || !has('vim9script')
  call add(g:pathogen_disabled, 'lsp')
endif
if !has('python3')
  call add(g:pathogen_disabled, 'vimspector')
endif
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
" Every terminal here runs a dark theme.  Inside tmux vim cannot read the background colour
" and falls back to 'light', whose defaults set a background but no foreground (Search,
" SpellBad, SpellCap): light-gray text on bright yellow, pink or cyan.  Before `syntax
" enable`, because changing 'background' reloads the default highlight groups.
set background=dark
syntax enable
filetype plugin indent on

" Options read by vim's own syntax/go.vim; nothing to guard.
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_build_constraints = 1

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
" Highlight groups are in .vim/colors.vim, GENERATED from colors.yaml by
" scripts/colors/render.sh (like keys.vim: plain vim, no plugin needed).
runtime colors.vim

" -- plugins (all optional) ------------------------------------------------------------
" A plain `let g:` never errors, so settings need no guard; commands do.
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
" gopls reports Go diagnostics; syntastic would show them twice.
let g:syntastic_mode_map = {'mode': 'active', 'passive_filetypes': ['go']}

" Language servers (yegappan/lsp), registered once plugins have loaded.  Each server is
" skipped when its binary is missing; see vimide#lsp_setup.
if !empty(globpath(&runtimepath, 'autoload/vimide.vim'))
  augroup vimide_lsp
    autocmd!
    autocmd VimEnter * call vimide#lsp_setup()
  augroup END
endif

" Debugger (vimspector): the adapter and launch configurations live in the repo, so a
" project needs no .vimspector.json of its own and no gadget is downloaded.
let g:vimspector_base_dir = s:vimdir . '/vimspector-config'

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
set statusline +=%6*                    "diagnostics: syntastic flag, then LSP [E:n W:n]
set statusline +=%{exists('*SyntasticStatuslineFlag')?SyntasticStatuslineFlag():''}
set statusline +=%{exists('g:loaded_lsp')?vimide#lsp_status():''}
set statusline +=%*
set statusline +=%2*%m%*                "modified flag
set statusline +=%1*%=%5l%*             "current line
set statusline +=%2*/%L%*               "total lines
set statusline +=%1*%4c\ %*             "column number
set statusline +=%2*0x%04B\ %*          "character under cursor

" -- keys ------------------------------------------------------------------------------
runtime keys.vim
