" Functions behind the keys in keys.vim and the clipboard hook in .vimrc.  Autoloaded on
" first use, so a vim that never presses Alt-h never reads this file.  Part of the core
" config, not a plugin: it ships in the repo and needs nothing installed.

" ---------------------------------------------------------------------------------------
" Focus: Alt-h/j/k/l and Alt-arrows.
"
" tmux forwards these into vim whenever the pane runs vim (.tmux/keys.conf, pass: vim), and
" <C-w>h in vim's leftmost window is a silent no-op, so the keystroke would be consumed
" with nothing done and focus trapped in the pane.  So: try the split move, and if the
" window number did not change we were at the edge -- ask tmux to move instead.  That is a
" tmux *command*, not a keystroke, so it cannot bounce back here and loop.
"
" Outside tmux the move simply does nothing at the edge.  Alt-Tab is the belt to these
" braces: bound at the tmux root with no vim passthrough, it always cycles panes.
" ---------------------------------------------------------------------------------------
let s:pane_dir = {'h': 'L', 'j': 'D', 'k': 'U', 'l': 'R'}

function! vimide#focus(dir) abort
  let l:from = winnr()
  execute 'wincmd ' . a:dir
  if winnr() == l:from && s:in_tmux()
    silent call system('tmux select-pane -' . s:pane_dir[a:dir])
  endif
endfunction

" ---------------------------------------------------------------------------------------
" Resize: Alt-Shift-h/j/k/l and Alt-Shift-arrows.  Flags follow tmux resize-pane:
" L narrows, R widens, U shortens, D lengthens.
"
" Same edge handoff as focus, decided by asking whether a neighbour exists in that axis
" BEFORE resizing.  Resizing first and checking for a change looks equivalent and is wrong
" one way in four: with a single window <C-w>- really does shrink it (vim leaves the freed
" row blank), so the handoff never fires and the lone window shrinks inside a full pane.
" ---------------------------------------------------------------------------------------
let s:wincmd = {'L': '<', 'R': '>', 'D': '+', 'U': '-'}

function! s:has_neighbour(flag) abort
  let l:axis = (a:flag ==# 'D' || a:flag ==# 'U') ? ['j', 'k'] : ['h', 'l']
  " winnr('h') returns the current window when there is none that way (vim 8.1.1140+).
  if has('patch-8.1.1140')
    let l:cur = winnr()
    return winnr(l:axis[0]) != l:cur || winnr(l:axis[1]) != l:cur
  endif
  return winnr('$') > 1
endfunction

function! vimide#resize(flag) abort
  if s:has_neighbour(a:flag)
    execute 'wincmd ' . s:wincmd[a:flag]
  elseif s:in_tmux()
    silent call system('tmux resize-pane -' . a:flag . ' 2')
  endif
endfunction

function! s:in_tmux() abort
  return !empty($TMUX) && executable('tmux')
endfunction

" ---------------------------------------------------------------------------------------
" Clipboard: every explicit yank also goes to the system clipboard, so `y` and Cmd-C mean
" the same thing.  Called from the TextYankPost hook in .vimrc.
"
" A pipe, because Debian's terminal vim is built -clipboard (no "+ register).  Not OSC 52,
" because gnome-terminal (VTE) never implemented it.  So this works locally only; over ssh
" yanks stay in vim and Shift-drag + Cmd-C is the answer, as in a shell pane.
"
" Wayland is tested before X11: a Wayland session often has xclip via XWayland, and it
" writes to the wrong clipboard there.
" ---------------------------------------------------------------------------------------
function! s:clip_cmd() abort
  if !exists('s:clip')
    let s:clip = ''
    if executable('pbcopy')
      let s:clip = 'pbcopy'
    elseif !empty($WAYLAND_DISPLAY) && executable('wl-copy')
      let s:clip = 'wl-copy'
    elseif !empty($DISPLAY) && executable('xclip')
      let s:clip = 'xclip -selection clipboard -in'
    elseif !empty($DISPLAY) && executable('xsel')
      let s:clip = 'xsel --clipboard --input'
    endif
  endif
  return s:clip
endfunction

function! vimide#clip(text) abort
  if !get(g:, 'vimide_clipboard', 1) || empty(a:text) || empty(s:clip_cmd())
    return
  endif
  call system(s:clip_cmd(), a:text)
endfunction
