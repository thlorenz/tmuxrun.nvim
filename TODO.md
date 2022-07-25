# TODOS

## Selector

- [x] allow _unselecting_ target
- [x] verify that selected target is still valid before sending keys
- [x] look into supporting a
  [ui-select](https://github.com/nvim-telescope/telescope-ui-select.nvim) popup instead of
  gathering info at the bottom of the editor via `vim.ui.select`
  - reference implementation [rust tools](https://github.com/simrat39/rust-tools.nvim)
- [x] handle selecting windows if names clash (add id to title + select by id)
- [x] handle case where we only have one pane and it is our vim session in which case the
  `defaultPaneIndex` comes back as `nil` (selector.lua:91)
- [x] using pane id to identify target which allows moving pane around in the window without
      loosing it
- [x] falling back to pane at same index as target pane should it have been destroyed
      (configurable)

## Persistence

- [x] optionally save last selected target to disk and reload on startup
- [x] save last command
    - this may have to happen on nvim close since we don't want to rewrite that settings file
      each time the user executes a command (unless we ensure to do this only if the command
      changed)

## Runner

- [x] repeat last command
- [x] bring window to front when sending keys (if its's in the background) configurable
- [x] clear sequence doesn't really work, prefixing with `clear;` does
- [x] resolve things like `%` (to current path) configurable
  - only supports replacing one occurrence which should cover 90% of cases
- [x] save (current file | all files) before running command configurable
- [x] SendCtrlC
- [x] SendCtrlD
- [x] SendUp (repeats whatever was executed last in the pane)
  - this is very useful when a command was executed in the pane already and we just want to
    repeat it without copy/pasting it and send via `TmuxCommand`
- [x] should not protect vim pane if we selected another session
  - which means that we want to be able to select a pane with the same number as our vim pane
    when it is in a different session and/or window
  - right now if we have vim open in pane one that pane is blocked in all sessions and windows

## Maybe Later

- [-] FocusRunnerPane and optionally zoom it (might not be possible across sessions)

## Won't do

- [ ] save command history to disk and reload via command or automatically if so configured
  - there should be two types of histories, one per project and one where we show all commands
    from all projects
  - [ ] integrate command history with telescope
  `:Telescope command_history` fuzzy searched for `TmuxCommand` provides that functionality and
  more.

- [ ] KillRunnerPane (covered by `TmuxCtrlD`


