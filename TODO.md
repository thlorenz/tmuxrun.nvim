# TODOS

## Selector

- [x] allow _unselecting_ target
- [x] verify that selected target is still valid before sending keys
- [-] look into supporting a
  [ui-select](https://github.com/nvim-telescope/telescope-ui-select.nvim) popup instead of
  gathering info at the bottom of the editor via `vim.ui.select`
  - reference implementation [rust tools](https://github.com/simrat39/rust-tools.nvim)
- [ ] handle selecting windows if names clash (add id to title + select by id)
- [ ] KillRunnerPane (low priority)

## Persistence

- [ ] optionally save last selected target to disk and reload on startup
- [ ] save command history to disk and reload via command or automatically if so configured
  - there should be two types of histories, one per project and one where we show all commands
    from all projects

It would be very nice to have multiple setups since they depend on the project.
Either we key them by the full path to the root of the current vim session or allow users to
label them. (similar to [startify](https://github.com/mhinz/vim-startify)).
The code startify uses to save the sessions [in
viml](https://github.com/mhinz/vim-startify/blob/master/autoload/startify.vim#L215)

We could also save the target info inside a `.tmuxrun.json` file or similar in the current vim
root and look for it at startup (configurable) or only when `TmuxLoadTarget` is called.

## Runner

- [x] repeat last command
- [x] bring window to front when sending keys (if its's in the background) configurable
- [ ] store command history and allow selecting one 
- [x] clear sequence doesn't really work, prefixing with `clear;` does
- [ ] save (current file | all files) before running command configurable
- [ ] resolve things like `%` (to current path) configurable
- [ ] SendCtrlD
- [ ] SendCtrlC
- [ ] SendUp (repeats whatever was executed last in the pane)
  - this is very useful when a command was executed in the pane already and we just want to
    repeat it without copy/pasting it and send via `TmuxCommand`
- [ ] integrate command history with telescope
- [ ] should not protect vim pane if we selected another session
  - which means that we want to be able to select a pane with the same number as our vim pane
    when it is in a different session and/or window
  - right now if we have vim open in pane one that pane is blocked in all sessions and windows

## Tmux

- [ ] FocusRunnerPane and optionally zoom it (might not be possible across sessions)
