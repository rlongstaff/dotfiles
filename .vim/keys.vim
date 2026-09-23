" GENERATED from keys.yaml by render.sh. Edit the yaml, not this file.
" Sourced by .vimrc (runtime keys.vim).  Functions live in autoload/vimide.vim.

" Terminal vim sees Alt+letter as ESC + letter and does not decode it, so each one is
" declared first.  Alt+arrow needs no declaration (and set <M-Up>= is E518).
if !has('gui_running')
  for s:k in ['h', 'j', 'k', 'l', 'H', 'J', 'K', 'L']
    execute 'set <M-' . s:k . ">=\<Esc>" . s:k
  endfor
  unlet s:k
endif

" -- editing ----------------------------------------------------------------------
nnoremap <silent> <CR> :nohlsearch<CR><CR>
nnoremap <C-Up> <C-u>
inoremap <C-Up> <C-u>
vnoremap <C-Up> <C-u>
nnoremap <C-Down> <C-d>
inoremap <C-Down> <C-d>
vnoremap <C-Down> <C-d>
nnoremap <C-a> <Home>
inoremap <C-a> <Home>
vnoremap <C-a> <Home>
nnoremap <C-e> <End>
inoremap <C-e> <End>
vnoremap <C-e> <End>
nnoremap <C-t> :NERDTreeToggle<CR>

" -- focus ------------------------------------------------------------------------
nnoremap <silent> <M-h> :call vimide#focus('h')<CR>
inoremap <silent> <M-h> <C-o>:call vimide#focus('h')<CR>
vnoremap <silent> <M-h> <Esc>:call vimide#focus('h')<CR>
nnoremap <silent> <M-j> :call vimide#focus('j')<CR>
inoremap <silent> <M-j> <C-o>:call vimide#focus('j')<CR>
vnoremap <silent> <M-j> <Esc>:call vimide#focus('j')<CR>
nnoremap <silent> <M-k> :call vimide#focus('k')<CR>
inoremap <silent> <M-k> <C-o>:call vimide#focus('k')<CR>
vnoremap <silent> <M-k> <Esc>:call vimide#focus('k')<CR>
nnoremap <silent> <M-l> :call vimide#focus('l')<CR>
inoremap <silent> <M-l> <C-o>:call vimide#focus('l')<CR>
vnoremap <silent> <M-l> <Esc>:call vimide#focus('l')<CR>
nnoremap <silent> <M-Left> :call vimide#focus('h')<CR>
inoremap <silent> <M-Left> <C-o>:call vimide#focus('h')<CR>
vnoremap <silent> <M-Left> <Esc>:call vimide#focus('h')<CR>
nnoremap <silent> <M-Down> :call vimide#focus('j')<CR>
inoremap <silent> <M-Down> <C-o>:call vimide#focus('j')<CR>
vnoremap <silent> <M-Down> <Esc>:call vimide#focus('j')<CR>
nnoremap <silent> <M-Up> :call vimide#focus('k')<CR>
inoremap <silent> <M-Up> <C-o>:call vimide#focus('k')<CR>
vnoremap <silent> <M-Up> <Esc>:call vimide#focus('k')<CR>
nnoremap <silent> <M-Right> :call vimide#focus('l')<CR>
inoremap <silent> <M-Right> <C-o>:call vimide#focus('l')<CR>
vnoremap <silent> <M-Right> <Esc>:call vimide#focus('l')<CR>

" -- resize -----------------------------------------------------------------------
nnoremap <silent> <M-H> :call vimide#resize('L')<CR>
inoremap <silent> <M-H> <C-o>:call vimide#resize('L')<CR>
vnoremap <silent> <M-H> <Esc>:call vimide#resize('L')<CR>
nnoremap <silent> <M-J> :call vimide#resize('D')<CR>
inoremap <silent> <M-J> <C-o>:call vimide#resize('D')<CR>
vnoremap <silent> <M-J> <Esc>:call vimide#resize('D')<CR>
nnoremap <silent> <M-K> :call vimide#resize('U')<CR>
inoremap <silent> <M-K> <C-o>:call vimide#resize('U')<CR>
vnoremap <silent> <M-K> <Esc>:call vimide#resize('U')<CR>
nnoremap <silent> <M-L> :call vimide#resize('R')<CR>
inoremap <silent> <M-L> <C-o>:call vimide#resize('R')<CR>
vnoremap <silent> <M-L> <Esc>:call vimide#resize('R')<CR>
nnoremap <silent> <M-S-Left> :call vimide#resize('L')<CR>
inoremap <silent> <M-S-Left> <C-o>:call vimide#resize('L')<CR>
vnoremap <silent> <M-S-Left> <Esc>:call vimide#resize('L')<CR>
nnoremap <silent> <M-S-Down> :call vimide#resize('D')<CR>
inoremap <silent> <M-S-Down> <C-o>:call vimide#resize('D')<CR>
vnoremap <silent> <M-S-Down> <Esc>:call vimide#resize('D')<CR>
nnoremap <silent> <M-S-Up> :call vimide#resize('U')<CR>
inoremap <silent> <M-S-Up> <C-o>:call vimide#resize('U')<CR>
vnoremap <silent> <M-S-Up> <Esc>:call vimide#resize('U')<CR>
nnoremap <silent> <M-S-Right> :call vimide#resize('R')<CR>
inoremap <silent> <M-S-Right> <C-o>:call vimide#resize('R')<CR>
vnoremap <silent> <M-S-Right> <Esc>:call vimide#resize('R')<CR>

" -- code -------------------------------------------------------------------------
nnoremap <silent> <F12> :call vimide#lsp('definition')<CR>
inoremap <silent> <F12> <C-o>:call vimide#lsp('definition')<CR>
nnoremap <silent> <C-S-F12> :call vimide#lsp('declaration')<CR>
inoremap <silent> <C-S-F12> <C-o>:call vimide#lsp('declaration')<CR>
nnoremap <silent> <C-F12> :call vimide#lsp('implementation')<CR>
inoremap <silent> <C-F12> <C-o>:call vimide#lsp('implementation')<CR>
nnoremap <silent> <S-F12> :call vimide#lsp('references')<CR>
inoremap <silent> <S-F12> <C-o>:call vimide#lsp('references')<CR>
nnoremap <silent> <M-F12> :call vimide#lsp('hover')<CR>
inoremap <silent> <M-F12> <C-o>:call vimide#lsp('hover')<CR>
nnoremap <F2> :call vimide#lsp('rename')<CR>

" -- debug ------------------------------------------------------------------------
nnoremap <silent> <F5> :call vimide#debug('continue')<CR>
nnoremap <silent> <S-F5> :call vimide#debug('stop')<CR>
nnoremap <silent> <C-F5> :call vimide#debug('restart')<CR>
nnoremap <silent> <F9> :call vimide#debug('breakpoint')<CR>
nnoremap <silent> <F10> :call vimide#debug('over')<CR>
nnoremap <silent> <F11> :call vimide#debug('into')<CR>
nnoremap <silent> <S-F11> :call vimide#debug('out')<CR>
nnoremap <silent> <F8> :call vimide#debug('eval')<CR>
