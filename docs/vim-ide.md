# vim IDE quickstart (Go)

Open a `.go` file inside a Go module and it works: completion pops up as you type, F12 jumps
to a definition, errors are underlined, and F5 starts the debugger. This page covers the keys
and what you see on screen. Every key is defined in `keys.yaml` and listed
in `keyboard-cheatsheet.md`; vim's own keys are in `vim-defaults.md`.

Go is the only language wired up so far. Other languages use the same pieces and are on the
backlog.

## Try it in 60 seconds

1. `vim main.go` (any file in a directory with a `go.mod`)
2. Type `fmt.Pri` in insert mode: a popup lists `Print`, `Printf`, `Println`
3. `Ctrl-n` to pick one, `Ctrl-y` to accept it
4. `Esc`, put the cursor on a function name, press `F12`: you land on its definition
5. `Ctrl-o` jumps back
6. Put the cursor on a line in `main()`, press `F9` (breakpoint), then `F5` and pick
   "Launch package": the program stops on that line

## What it's built from

| Piece | Does | Upstream docs |
| ----- | ---- | ------------- |
| vim's `syntax/go.vim` | highlighting | [vim-go `g:go_highlight_*` options][vim-go-doc] (the file is maintained there) |
| [yegappan/lsp][lsp] | LSP client: completion, go to, diagnostics, formatting | [`doc/lsp.txt`][lsp-doc], [server configs][lsp-configs] |
| [gopls][gopls] | the Go language server | [gopls features][gopls-features], [settings][gopls-settings] |
| [vimspector][vimspector] | debugger UI (DAP client) | [README][vimspector], [`doc/vimspector.txt`][vimspector-doc], [configuration reference][vimspector-config] |
| [delve][delve] | the Go debugger, run as `dlv dap` | [delve docs][delve-docs], [DAP server][delve-dap] |

The two plugins are git submodules in `.vim/bundle/` and load through pathogen. The
upstream doc links point at the commits pinned here, so they describe the installed
version.

**Requirements.** yegappan/lsp needs vim 9.0+. vimspector needs vim built with `+python3`
(on Debian that means `vim-nox`, not `vim`; check with `vim --version | grep python3`).
`gopls` and `dlv` must be on `PATH`:

```sh
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
```

If any of these is missing, vim still starts without errors: the keys fall back to plain
vim or print one line saying what's missing.

## Completion (prediction)

Suggestions appear automatically as you type, including right after a `.`. Nothing is
selected or inserted until you choose.

| Key (insert mode) | Does |
| ----------------- | ---- |
| `Ctrl-n` / `Ctrl-p` | select next / previous suggestion (inserts it as a preview) |
| `Down` / `Up` | select next / previous without inserting it |
| `Ctrl-y` | **accept** the selected suggestion (works after either way of selecting) |
| `Enter` | after `Down`/`Up`: accept, no new line. After `Ctrl-n`/`Ctrl-p`: accept **and** start a new line. Nothing selected: close the popup |
| `Ctrl-e` | close the popup and put back what you typed |
| `Esc` | close the popup and leave insert mode |
| `Tab` | not a completion key: inserts a tab |

- The popup narrows as you type. Matching is fuzzy, so `prf` finds `Printf`.
- The selected suggestion's documentation shows in a second popup beside the menu.
- Inside a call's parentheses, a popup shows the function signature (for example
  `Printf(format string, a ...any)`). It updates as you type arguments.
- With no language server (another filetype, or gopls missing), `Ctrl-n` / `Ctrl-p` still
  complete words from open buffers. That's vim's own keyword completion.

Upstream: [`:help lsp-ins-mode-completion`][lsp-doc] and the `autoComplete`,
`completionMatcher` and `showSignature` options in the same file.

## Navigation

| Key | Does | Without a server |
| --- | ---- | ---------------- |
| `F12` | go to definition | tag jump (`Ctrl-]`), if there is a tags file |
| `Ctrl-Shift-F12` | go to declaration | vim's `gD` |
| `Ctrl-F12` | go to implementation (interface to concrete type) | one-line message |
| `Shift-F12` | list references (location list; `Enter` jumps) | one-line message |
| `Alt-F12` | hover: type and docs in a popup | vim's `K` |
| `F2` | rename the symbol everywhere (asks for the new name) | one-line message |
| `Ctrl-]` | go to definition (gopls answers vim's tag lookup) | tag jump |
| `Ctrl-o` / `Ctrl-i` | jump back / forward | same |

More commands without keys: `:LspGotoTypeDef`, `:LspPeekDefinition` (opens in a popup),
`:LspDocumentSymbol`, `:LspSymbolSearch {name}`, `:LspOutline`, `:LspIncomingCalls`,
`:LspCodeAction`, `:LspOrganizeImports`. The full list is in [`doc/lsp.txt`][lsp-doc].

## Errors and warnings

gopls checks the file as you type and again on save. syntastic is turned off for Go so the
same errors don't show up twice.

**In the text.** The code with the problem is highlighted with vim's spell-check colours:

| Severity | Highlight group | Linked to (default look) |
| -------- | --------------- | ------------------------ |
| error | `LspDiagInlineError` | `SpellBad` (usually red) |
| warning | `LspDiagInlineWarning` | `SpellCap` (usually blue) |
| info | `LspDiagInlineInfo` | `SpellRare` |
| hint | `LspDiagInlineHint` | `SpellLocal` |

**In the sign column** (left of the line numbers): `E>` error, `W>` warning, `I>` info,
`H>` hint. The column appears only while the buffer has a sign in it.

**Reading the message.** Nothing is shown automatically (virtual text is off because it
crowds narrow panes). Use:

| Command | Does |
| ------- | ---- |
| `:LspDiag current` | show the message for the cursor line in a popup |
| `:LspDiag next` / `:LspDiag prev` | jump to the next / previous problem |
| `:LspDiagNextWrap` / `:LspDiagPrevWrap` | same, wrapping at the ends of the file |
| `:LspDiag first` / `:LspDiag last` | jump to the first / last problem |
| `:LspDiag show` | list every problem in the location list (`Enter` jumps, `:lclose` closes) |
| `:LspDiag highlight toggle` | turn the highlighting and signs off / on |

There are no keys for next / previous yet: `vimide#lsp('diag_next')` and `('diag_prev')`
exist and are listed, commented out, in `keys.yaml` (group `code`). Pick a key, uncomment,
run `scripts/keyboard/render.sh`.

To change the colours, link the groups above in `.vimrc`, for example
`highlight link LspDiagInlineError ErrorMsg`. Upstream: [`:help lsp-diagnostics`][lsp-doc]
and [`:help lsp-highlight-groups`][lsp-doc].

## Status bar

The status line at the bottom of each window reads, left to right:

```
[unix][go] /home/me/prj/t/main.go [E:1 W:0][+]        12/40  7 0x0066
 │     │    │                      │       │            │  │  │  │
 │     │    │                      │       │            │  │  │  └ character under the cursor, hex
 │     │    │                      │       │            │  │  └ column
 │     │    │                      │       │            │  └ total lines
 │     │    │                      │       │            └ current line
 │     │    │                      │       └ [+] = unsaved changes
 │     │    │                      └ LSP errors / warnings in this buffer
 │     │    └ full path
 │     └ filetype
 └ line endings
```

- `[E:n W:n]` only appears when the buffer has a server attached and at least one error or
  warning. No count means clean (or no server; check with `:LspShowAllServers`).
- For another filetype, syntastic's flag can appear in the same spot.

## Formatting

Saving a Go file formats it through gopls (same result as `gofmt`). Indentation is tabs
shown 4 wide, following gofmt; other filetypes keep the global 2-space indent. Imports are
not fixed on save. Run `:LspOrganizeImports` to add and remove them. `:LspFormat` formats
without saving.

## Debugging

| Key (normal mode) | Does |
| ----------------- | ---- |
| `F5` | start (asks which configuration) / continue to the next breakpoint |
| `Shift-F5` | stop the program and close the debugger windows |
| `Ctrl-F5` | restart with the same configuration |
| `F9` | toggle a breakpoint on the cursor line |
| `F10` | step over |
| `F11` | step into |
| `Shift-F11` | step out |
| `F8` | show the value of the expression under the cursor in a popup |

`F5` asks which configuration to run. All three work for every Go file with no project setup:

| Configuration | Runs |
| ------------- | ---- |
| Launch package | the package in the current file's directory (`dlv debug`) |
| Launch test | that package's tests (`dlv test`) |
| Attach to process | a running process; asks for the PID |

**Screen layout while debugging:**

| Window | Shows | Keys in it |
| ------ | ----- | ---------- |
| Variables (top left) | locals, `+` to expand | `Enter` expand / collapse, `Ctrl-Enter` set the value |
| Watches | expressions you add | `i`, type an expression, `Enter` |
| Stack trace | threads and frames | `Enter` jumps to that frame |
| code (right) | source; `▶` marks the current line (highlighted), `●` marks each breakpoint | the keys above |
| terminal | the program's own output | |
| Console (bottom) | delve messages and evaluation results | `i`, type an expression, `Enter` |

Commands: `:VimspectorEval {expr}`, `:VimspectorWatch {expr}`, `:VimspectorBreakpoints`
(list them all), `:VimspectorShowOutput Console`. Upstream: [`doc/vimspector.txt`][vimspector-doc]
and the [vimspector README][vimspector].

**Your own configurations.** The defaults live in
`.vim/vimspector-config/configurations/linux/go/go.json` (macOS reads the same file through
a symlink). For program arguments or environment variables, add a `.vimspector.json` to the
project root. The format is in the [configuration reference][vimspector-config], and the
delve-specific keys are in the [delve DAP docs][delve-dap]. The `delve` adapter runs the
`dlv` on `PATH`, so `:VimspectorInstall` is never needed.

## Where it lives in the repo

| File | Holds |
| ---- | ----- |
| `.vimrc` | plugin loading guards, Go highlight options, LSP start hook, statusline |
| `.vim/autoload/vimide.vim` | `vimide#lsp_setup` (server list: `s:servers`), `vimide#lsp`, `vimide#debug`, `vimide#lsp_status` |
| `.vim/after/ftplugin/go.vim` | Go indentation |
| `.vim/vimspector-config/` | delve adapter and Go launch configurations |
| `keys.yaml` | the F-keys (groups `code` and `debug`) |

## When something doesn't work

| Symptom | Check |
| ------- | ----- |
| No popup, no `[E:..]`, F12 says "no language server" | `:LspShowAllServers`, then `which gopls` in the shell vim started from |
| Server running but wrong answers | `:LspServer restart`; logs via `:LspServer debug on`, then `:LspServer debug messages` |
| F5 says "debugger not available" | `vim --version \| grep python3` must show `+python3` |
| Debugger starts then stops | `which dlv`; `:VimspectorToggleLog` for the log |
| F11 makes the terminal full screen | gnome-terminal: run `scripts/install.d/30-keyboard.sh` |
| `:help lsp` or `:help vimspector` says no help | run `:Helptags` once (pathogen builds the plugins' help index) |

[lsp]: https://github.com/yegappan/lsp
[lsp-doc]: https://github.com/yegappan/lsp/blob/58eac06e81bad174cfa897614ae01adf0d31d10a/doc/lsp.txt
[lsp-configs]: https://github.com/yegappan/lsp/blob/58eac06e81bad174cfa897614ae01adf0d31d10a/doc/configs.md
[vimspector]: https://github.com/puremourning/vimspector/blob/34099d18d8957bb3db5f396c8ca993ffb246a437/README.md
[vimspector-doc]: https://github.com/puremourning/vimspector/blob/34099d18d8957bb3db5f396c8ca993ffb246a437/doc/vimspector.txt
[vimspector-config]: https://puremourning.github.io/vimspector/configuration.html
[gopls]: https://go.dev/gopls/
[gopls-features]: https://go.dev/gopls/features/
[gopls-settings]: https://go.dev/gopls/settings
[delve]: https://github.com/go-delve/delve
[delve-docs]: https://github.com/go-delve/delve/tree/master/Documentation
[delve-dap]: https://github.com/go-delve/delve/blob/master/Documentation/api/dap/README.md
[vim-go-doc]: https://github.com/fatih/vim-go/blob/master/doc/vim-go.txt
