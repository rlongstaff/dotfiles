set textwidth=100
set tabstop=2
set shiftwidth=2
set expandtab
set smarttab
set autoindent
set smartindent
set wrap
set backspace=eol,start,indent
set ruler
set number
set numberwidth=5
set hlsearch
set showmatch

" Map PageUp and PageDown to Left and Right arrows
"  because Dell keyboards are stupid
nnoremap <PageUp> <Left>
nnoremap <PageDown> <Right>
inoremap <PageUp> <Left>
inoremap <PageDown> <Right>
vnoremap <PageUp> <Left>
vnoremap <PageDown> <Right>

" Map Ctrl+Up and Ctrl+Down to PageUp and PageDown functions
nnoremap <C-Up> <C-u>
nnoremap <C-Down> <C-d>
inoremap <C-Up> <C-u>
inoremap <C-Down> <C-d>
vnoremap <C-Up> <C-u>
vnoremap <C-Down> <C-d>

syntax enable
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

"set list
"set listchars=tab:>~,trail:~

"set background=dark
highlight LineNr ctermbg=black   ctermfg=darkblue
set laststatus=2
"set statusline +=%1*\ %n\ %*            "buffer number
set statusline=
set statusline +=%5*[%{&ff}]%*          "file format
set statusline +=%3*%y%*                "file type
set statusline +=%4*\ %<%F%*            "full path

set statusline +=%#warningmsg#
set statusline +=%{SyntasticStatuslineFlag()}
set statusline +=%*

set statusline +=%2*%m%*                "modified flag
set statusline +=%1*%=%5l%*             "current line
set statusline +=%2*/%L%*               "total lines
set statusline +=%1*%4c\ %*             "column number
set statusline +=%2*0x%04B\ %*          "character under cursor

execute pathogen#infect()
