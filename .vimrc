set textwidth=78
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent
set smartindent
inoremap # X#
set backspace=eol,start,indent

set wrap

set ruler
set laststatus=2
"set statusline=%F%m%r%h%w[%L][%{&ff}]%y[%p%%][%04l,%04v]
"set statusline=%F%m%r%h%w%<\ %{&ff}\ %Y\ [0x\%02.2B]\ %=l/%L,%v\ %p%%
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

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

set number
set numberwidth=5
highlight LineNr ctermbg=black   ctermfg=darkblue

set hlsearch
set showmatch

syntax enable
"set background=dark

set list
set listchars=tab:>~,trail:~

execute pathogen#infect()
