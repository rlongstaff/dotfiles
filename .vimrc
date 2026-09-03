" Must come first, and must be explicit.  Vim only turns 'compatible' off by itself when it
" finds a vimrc on the normal search path; started as `vim -u .vimrc` it does not, and
" everything below then runs in vi-compatible mode.  pathogen.vim is the loud symptom --
" it opens with `if ... || &cp | finish | endif`, so under -u it silently defines no
" functions at all and pathogen#infect() fails with E117.
set nocompatible

" Plugins load first, so 'runtimepath' is complete before anything below can reference
" them.  Guarded: pathogen lives in .vim/, which is not on 'runtimepath' until install.sh
" has linked ~/.vim, and vim started with a different $HOME never sees it at all.
" Without the guard that is E117 on startup and the core settings below never apply.
if !empty(globpath(&runtimepath, 'autoload/pathogen.vim'))
  execute pathogen#infect()
endif

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
set mouse=a

" vim picks 'ttymouse' from TERM and lands on 'xterm' under TERM=tmux-256color, which is
" the oldest of the mouse protocols: it encodes the position in single bytes, so it cannot
" report a click past column 223, and it does not distinguish a drag from a move.  Both
" matter here -- a wide terminal is normal, and the drag-release is what triggers the
" clipboard copy below.  'sgr' has neither limit and every terminal on the target list
" speaks it (xterm, VTE, foot, iTerm2 and tmux itself).
if has('mouse_sgr')
  set ttymouse=sgr
endif

" PageUp/PageDown page, in every mode, which is what they do in the terminal and in tmux
" scrollback too -- one key, one meaning across all three layers.
"
" These used to be remapped to Left/Right for cramped arrow clusters.  That made vim the
" only layer where the key did something else, so it went; plain arrows and h/l still
" cover horizontal movement.  No mapping is needed -- paging is vim's own default for
" these keys; the mappings that used to be here were the deviation.

" Ctrl+Up / Ctrl+Down stay half-page, a finer step than PageUp/PageDown's full screen.
nnoremap <C-Up> <C-u>
nnoremap <C-Down> <C-d>
inoremap <C-Up> <C-u>
inoremap <C-Down> <C-d>
vnoremap <C-Up> <C-u>
vnoremap <C-Down> <C-d>

" Alt/Option is the in-terminal command modifier -- see .keyboard/README.md.  M-h/j/k/l
" moves between vim splits; .tmux.conf forwards those keys here when the pane is running
" vim, so one keystroke crosses both the tmux pane and vim split boundary.
"
" Terminal vim receives Alt as a two-byte ESC-prefixed sequence rather than a distinct
" key, so each one has to be declared before it can be mapped.  gvim already knows them,
" hence the has('gui_running') guard.  ttimeoutlen keeps a bare Escape responsive while
" still leaving time for the second byte to arrive.
if !has('gui_running')
  " Alt+letter arrives as a bare ESC prefix; Alt-Shift+letter as ESC + the capital.
  for s:k in ['h', 'j', 'k', 'l', 'H', 'J', 'K', 'L']
    execute "set <M-" . s:k . ">=\<Esc>" . s:k
  endfor

  " Alt+Arrow needs no declaration.  It arrives as the xterm CSI form
  " ESC [ 1 ; <mod> <letter> (modifier 3 = Alt), which vim decodes natively -- unlike
  " Alt+letter, whose bare-ESC-prefix form it does not.  Declaring it is not merely
  " redundant but an error: `set <M-Up>=` is E518, because that syntax only accepts keys
  " vim carries as termcap entries and the modified arrows are not among them.

  set ttimeout
  set ttimeoutlen=25
endif

" Alt moves focus, Alt-Shift resizes -- the two differ only by Shift.  Each is driven off
" one table covering both key families, so the cursor keys mirror h/j/k/l rather than
" being a second, separately-maintained set of bindings that can drift.

" Focus has to hand back to tmux at the edge of the split layout, or focus is trapped:
" .tmux.conf forwards M-h/j/k/l into vim whenever the pane runs vim, and plain <C-w>h in
" vim's leftmost window is a silent no-op -- so the keystroke is consumed by vim, vim does
" nothing with it, and there is no way back out to the tmux pane on that side.
"
" The fix is the vim-tmux-navigator trick without the plugin: try the split move, and if
" the window number did not change we were already at the edge, so ask tmux to move
" instead.  That is a tmux *command*, not a keystroke, so it cannot bounce back here and
" loop.
"
" Guarded on $TMUX and executable('tmux'), so outside tmux this degrades to exactly the
" old behaviour: the move simply does nothing at the edge.
"
" M-Tab is the belt to this braces -- it is bound at the tmux root with no vim
" passthrough, so it always cycles tmux panes no matter what the pane is running.
let s:vimide_pane_dir = {'h': 'L', 'j': 'D', 'k': 'U', 'l': 'R'}

function! s:VimIdeFocus(dir) abort
  let l:from = winnr()
  execute 'wincmd ' . a:dir
  if winnr() == l:from && !empty($TMUX) && executable('tmux')
    silent call system('tmux select-pane -' . s:vimide_pane_dir[a:dir])
  endif
endfunction

for [s:key, s:dir] in [['h', 'h'], ['j', 'j'], ['k', 'k'], ['l', 'l'],
                     \  ['Left', 'h'], ['Down', 'j'], ['Up', 'k'], ['Right', 'l']]
  execute 'nnoremap <silent> <M-' . s:key . '> :call <SID>VimIdeFocus("' . s:dir . '")<CR>'
  execute 'inoremap <silent> <M-' . s:key . '> <C-o>:call <SID>VimIdeFocus("' . s:dir . '")<CR>'
  execute 'vnoremap <silent> <M-' . s:key . '> <Esc>:call <SID>VimIdeFocus("' . s:dir . '")<CR>'
endfor

" Resize directions match tmux's resize-pane -L/-D/-U/-R: left narrows, right widens, up
" shortens, down lengthens.
"
" Same edge handoff as focus, for the same reason: tmux forwards these into vim whenever
" the pane runs vim, and a vim with no split in that axis has nothing to resize, so the
" keystroke was consumed and the tmux pane never moved.  A resize at the edge is not a
" dead end the way trapped focus is -- but it is still a key that silently does nothing,
" which is exactly what this config exists to remove.
"
" Detected by measuring rather than by counting windows: `winheight()` is the honest test
" of whether `<C-w>+` did anything, and it stays correct in layouts where a window has a
" neighbour in one axis and not the other.  It also means a resize that vim refuses
" because the window is already at 'winminwidth' hands off to tmux, which is the useful
" reading of the keypress anyway.
"
" Decided by asking whether a neighbouring window exists in that axis, NOT by resizing and
" checking whether anything moved.  The measure-first-then-compare approach looks equivalent
" and is wrong in exactly one direction: with a single window, `<C-w>-` really does shrink
" it -- vim just leaves the freed row blank -- so the height *does* change, the handoff
" never fires, and repeated presses shrink the lone window inside a full-size pane instead
" of resizing the pane.  `<C-w>+`, `<C-w><` and `<C-w>>` are all genuine no-ops there,
" which is what makes the bug so easy to miss: three directions out of four work.
"
" Consequence worth stating: with no neighbour, vim is not asked to resize at all.  Outside
" tmux that makes the key a no-op rather than shrinking the lone window.  That is the point
" -- a window with nothing beside it has nothing to resize against.
"
" The dict is keyed on the tmux flag so the mapping RHS carries only a bare letter.
" Passing the wincmd character instead would put a literal '<' into a :nnoremap argument,
" where vim's own key-notation parser can reach it.
let s:vimide_resize = {'L': '<', 'R': '>', 'D': '+', 'U': '-'}

function! s:VimIdeNeighbour(flag) abort
  let l:axis = (a:flag ==# 'D' || a:flag ==# 'U') ? ['j', 'k'] : ['h', 'l']
  " winnr('h') and friends return the *current* window number when there is no window that
  " way, which is the whole test.  Added in 8.1.1140; older vim falls back to the only
  " thing it can say for certain, which covers the common case of vim with no splits.
  if has('patch-8.1.1140')
    let l:cur = winnr()
    return winnr(l:axis[0]) != l:cur || winnr(l:axis[1]) != l:cur
  endif
  return winnr('$') > 1
endfunction

function! s:VimIdeResize(flag) abort
  if s:VimIdeNeighbour(a:flag)
    execute 'wincmd ' . s:vimide_resize[a:flag]
  elseif !empty($TMUX) && executable('tmux')
    silent call system('tmux resize-pane -' . a:flag . ' 2')
  endif
endfunction

for [s:key, s:flag] in [['H', 'L'], ['J', 'D'], ['K', 'U'], ['L', 'R'],
                      \  ['S-Left', 'L'], ['S-Down', 'D'], ['S-Up', 'U'], ['S-Right', 'R']]
  execute 'nnoremap <silent> <M-' . s:key . '> :call <SID>VimIdeResize("' . s:flag . '")<CR>'
  execute 'inoremap <silent> <M-' . s:key . '> <C-o>:call <SID>VimIdeResize("' . s:flag . '")<CR>'
  execute 'vnoremap <silent> <M-' . s:key . '> <Esc>:call <SID>VimIdeResize("' . s:flag . '")<CR>'
endfor

" ---------------------------------------------------------------------------------------
" Clipboard.  See .keyboard/README.md.
"
" This vim is built -clipboard (`vim --version | grep clipboard`), which is the normal case
" for the terminal vim Debian and the base OS images ship -- so "+y, "*y and
" 'clipboard=unnamedplus' are all unavailable and cannot be the mechanism.  That turns out
" to be a gift rather than a limitation: the alternative, OSC 52, is an escape sequence
" written to the terminal, so it is the only method that also works over ssh, where the
" remote vim has no clipboard to talk to but the local terminal does.
"
" Cmd-C cannot reach vim -- Cmd has no byte encoding -- so, exactly as in tmux, the rule is
" that a selection reaches the system clipboard the moment it is made rather than waiting
" for a key vim will never receive.
"
" Set g:vimide_clipboard = 0 before this file to turn the whole thing off.
let g:vimide_clipboard = get(g:, 'vimide_clipboard', 1)

" Terminals stop honouring OSC 52 somewhere in the tens of kilobytes and differ on where.
" Past the cap the sequence is dropped rather than sent half-formed, which would leave the
" terminal parsing the rest of the payload as keystrokes.
let g:vimide_clipboard_max = get(g:, 'vimide_clipboard_max', 74994)

function! s:VimIdeOsc52(text) abort
  if !g:vimide_clipboard || empty(a:text) || !filewritable('/dev/tty')
    return
  endif
  " base64_encode() and str2blob() are vim 9.1; older vim shells out to base64(1), which is
  " POSIX and present on every target including macOS.  split() with keepempty preserves a
  " trailing newline, so a linewise yank pastes as a line rather than losing its break.
  if exists('*base64_encode') && exists('*str2blob')
    let l:b64 = base64_encode(str2blob(split(a:text, "\n", 1)))
  else
    let l:b64 = substitute(system('base64 | tr -d "\n"', a:text), '[\r\n]', '', 'g')
  endif
  if len(l:b64) > g:vimide_clipboard_max
    return
  endif
  " Written straight to the controlling terminal.  Inside tmux this lands in the pane's
  " pty, tmux recognises OSC 52, stores it in its own paste buffer AND re-emits it to the
  " terminal it is attached to -- so one write serves vim's clipboard, tmux's buffer and
  " the system clipboard at once.  That is why nothing here special-cases $TMUX.
  call writefile(["\033]52;c;" . l:b64 . "\007"], '/dev/tty', 'b')
endfunction

" Any explicit yank goes to the system clipboard, so `y` and Cmd-C mean the same thing.
" Restricted to the yank operator on purpose: `d` and `c` fill vim's registers too, but a
" delete is not a copy anywhere else in this standard, and having it silently replace the
" clipboard is exactly the surprise the layer rules exist to prevent.
if exists('##TextYankPost')
  augroup vimide_clipboard
    autocmd!
    autocmd TextYankPost *
          \ if v:event.operator ==# 'y' |
          \   call s:VimIdeOsc52(join(v:event.regcontents, "\n")
          \        . (v:event.regtype ==# 'V' ? "\n" : '')) |
          \ endif
  augroup END
endif

" Mouse selection copies on release, which is what tmux's MouseDragEnd1Pane does one layer
" out.  Two deliberate differences from tmux, because vim's visual mode is not a
" copy-only mode the way tmux's is:
"
"   - the selection stays up afterwards (`gv`), so the drag can still be the start of a
"     `d`, `c` or `>` rather than only ever a copy;
"   - vim's own registers are put back exactly as they were, so only the *system*
"     clipboard changes.  Without that, mouse-selecting a target to paste over would
"     destroy the very text about to be pasted.
function! s:VimIdeClipVisual() abort
  let l:save = [getreg('"'), getregtype('"')]
  normal! gvy
  if !exists('##TextYankPost')
    call s:VimIdeOsc52(getreg('"'))
  endif
  call setreg('"', l:save[0], l:save[1])
  normal! gv
endfunction

xnoremap <silent> <LeftRelease> <LeftRelease>:<C-u>call <SID>VimIdeClipVisual()<CR>

" Selection highlight, identical to tmux's mode-style in .tmux.conf.
"
" Written as numbers, not names, because the two programs disagree about what the names
" mean: vim's 'Blue' is colour12 and its 'White' is colour15, while tmux's 'blue' is
" colour4 and its 'white' is colour7.  Writing `ctermbg=blue` here and `bg=blue` there
" looks like a match and produces two different colours.
"
" colour4 on colour15 is the classic selection pair and stays inside the 16 colours every
" terminal on the target list supports.  Setting ctermfg costs syntax colour inside the
" selection; that is the deliberate trade for a selection that looks the same in vim and in
" tmux scrollback, and reads on every background.
highlight Visual ctermbg=4 ctermfg=15

" Pasting needs no mapping.  Cmd-V is the terminal writing bytes into the tty, which vim
" reads like any other input.  What makes it paste cleanly rather than auto-indenting into
" a staircase is bracketed paste, which vim enables from terminfo when the terminal
" advertises it -- verified non-empty under TERM=tmux-256color, so the tmux path works too.
" 'pastetoggle' and :set paste are therefore not needed and are deliberately absent: they
" would disable this and every other insert-mode mapping while active.

syntax enable

" Inert when syntastic is absent -- a plain `let g:` never errors, so these need no guard.
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

" Guarded inline rather than calling SyntasticStatuslineFlag() directly: the statusline is
" re-evaluated on every redraw, so without syntastic loaded this is an E117 per keystroke,
" not a single startup error.  Expands to nothing when the plugin is absent.
set statusline +=%#warningmsg#
set statusline +=%{exists('*SyntasticStatuslineFlag')?SyntasticStatuslineFlag():''}
set statusline +=%*

set statusline +=%2*%m%*                "modified flag
set statusline +=%1*%=%5l%*             "current line
set statusline +=%2*/%L%*               "total lines
set statusline +=%1*%4c\ %*             "column number
set statusline +=%2*0x%04B\ %*          "character under cursor
