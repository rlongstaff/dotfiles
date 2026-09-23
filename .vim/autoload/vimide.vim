" Functions behind the keys in keys.vim and the hooks in .vimrc (clipboard, LSP setup,
" statusline).  Autoloaded on first use.  Part of the core config, not a plugin: it ships
" in the repo and needs nothing installed.  The LSP and debugger functions drive optional
" plugins, and fall back or say so when those are absent.

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
    silent call system(['tmux', 'select-pane', '-' . s:pane_dir[a:dir]])
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
    silent call system(['tmux', 'resize-pane', '-' . a:flag, '2'])
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
  " a:text is yanked buffer content, arbitrary and untrusted: pass it as system()'s {input}
  " so it goes over a pipe, never interpolated into a shell string.
  call system(s:clip_cmd(), a:text)
endfunction

" ---------------------------------------------------------------------------------------
" Language servers: yegappan/lsp (.vim/bundle/lsp), vim 9 only.
"
" vimide#lsp_setup runs on VimEnter, after pathogen has loaded the plugin.  A server whose
" binary is not on PATH is simply not registered, so that language keeps plain vim.  To add
" a language, add a line to s:servers.
"
" A buffer with a server attached gets b:vimide_lsp, which is what the keys and the
" statusline test.  It also gets 'tagfunc', so <C-]>, :tag and <C-w>] ask the server.
" ---------------------------------------------------------------------------------------
let s:servers = [
      \ {'name': 'gopls', 'filetype': ['go', 'gomod', 'gowork', 'gotmpl'],
      \  'path': 'gopls', 'args': ['serve']},
      \ ]

" Filetypes formatted by the server on every write.  gofmt style is not optional in Go.
let s:format_on_save = ['go']

function! vimide#lsp_setup() abort
  if !exists('*LspAddServer')
    return
  endif
  call LspOptionsSet({
        \ 'autoComplete': v:true,
        \ 'showSignature': v:true,
        \ 'autoHighlightDiags': v:true,
        \ 'showDiagWithVirtualText': v:false,
        \ 'completionMatcher': 'fuzzy',
        \ 'noNewlineInCompletion': v:true,
        \ })
  let l:found = []
  for l:server in s:servers
    if executable(l:server.path)
      call add(l:found, extend(copy(l:server), {'path': exepath(l:server.path)}))
    endif
  endfor
  if empty(l:found)
    return
  endif
  call LspAddServer(l:found)
  augroup vimide_lsp_buffer
    autocmd!
    autocmd User LspAttached call s:lsp_attached()
    autocmd User LspDetached silent! unlet b:vimide_lsp
  augroup END
endfunction

function! s:lsp_attached() abort
  let b:vimide_lsp = 1
  setlocal tagfunc=lsp#lsp#TagFunc
  if index(s:format_on_save, &filetype) >= 0
    augroup vimide_lsp_format
      autocmd! * <buffer>
      autocmd BufWritePre <buffer> if get(b:, 'vimide_lsp', 0) | silent LspFormat | endif
    augroup END
  endif
endfunction

" What the code keys (F12 and friends) run: the server when the buffer has one, else the
" nearest plain-vim command.  [lsp command, fallback normal-mode keys or '' for none]
let s:lsp_actions = {
      \ 'definition':     ['LspGotoDefinition',  "\<C-]>"],
      \ 'declaration':    ['LspGotoDeclaration', 'gD'],
      \ 'implementation': ['LspGotoImpl',        ''],
      \ 'references':     ['LspShowReferences',  ''],
      \ 'rename':         ['LspRename',          ''],
      \ 'hover':          ['LspHover',           'K'],
      \ 'diag_next':      ['LspDiagNextWrap',    ''],
      \ 'diag_prev':      ['LspDiagPrevWrap',    ''],
      \ }

function! vimide#lsp(action) abort
  let [l:cmd, l:fallback] = s:lsp_actions[a:action]
  if get(b:, 'vimide_lsp', 0)
    execute l:cmd
  elseif empty(l:fallback)
    echo 'vim-ide: ' . a:action . ' needs a language server for this filetype'
  else
    " <C-]> with no tags file is E433; say so in one line rather than a stack of errors.
    try
      execute 'normal! ' . l:fallback
    catch /^Vim\%((\a\+)\)\=:E\(426\|433\)/
      echo 'vim-ide: no language server and no tags for ' . expand('<cword>')
    endtry
  endif
endfunction

" Statusline slot: error and warning counts from the server, empty when there are none.
function! vimide#lsp_status() abort
  if !get(b:, 'vimide_lsp', 0)
    return ''
  endif
  let l:count = lsp#lsp#ErrorCount()
  if l:count.Error + l:count.Warn == 0
    return ''
  endif
  return printf(' [E:%d W:%d]', l:count.Error, l:count.Warn)
endfunction

" ---------------------------------------------------------------------------------------
" Debugger: vimspector (.vim/bundle/vimspector), which needs vim built +python3.
"
" The adapters and launch configurations are in .vim/vimspector-config (g:vimspector_base_dir
" in .vimrc).  Go uses the dlv on PATH through `dlv dap`.
" ---------------------------------------------------------------------------------------
let s:debug_actions = {
      \ 'continue':   ['vimspector#Continue', []],
      \ 'stop':       ['vimspector#Reset', []],
      \ 'restart':    ['vimspector#Restart', []],
      \ 'breakpoint': ['vimspector#ToggleBreakpoint', []],
      \ 'over':       ['vimspector#StepOver', []],
      \ 'into':       ['vimspector#StepInto', []],
      \ 'out':        ['vimspector#StepOut', []],
      \ 'eval':       ['vimspector#ShowEvalBalloon', [0]],
      \ }

function! vimide#debug(action) abort
  if !exists(':VimspectorReset')
    echo 'vim-ide: debugger not available (vimspector needs vim built with +python3)'
    return
  endif
  let [l:func, l:args] = s:debug_actions[a:action]
  call call(l:func, l:args)
endfunction
