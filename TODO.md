# TODOS

## Selector

- [x] allow _unselecting_ target
- [x] verify that selected target is still valid before sending keys
- [ ] look into supporting a
  [ui-select](https://github.com/nvim-telescope/telescope-ui-select.nvim) popup instead of
  gathering info at the bottom of the editor
- [ ] KillRunnerPane (low priority)

## Persistence

- [ ] optionally save last selected target to disk and reload on startup

It would be very nice to have multiple setups since they depend on the project.
Either we key them by the full path to the root of the current vim session or allow users to
label them. (similar to [startify](https://github.com/mhinz/vim-startify)).
The code startify uses to save the sessions [in
viml](https://github.com/mhinz/vim-startify/blob/master/autoload/startify.vim#L215)

We could also save the target info inside a `.tmuxrun.json` file or similar in the current vim
root and look for it at startup (configurable) or only when `TmuxLoadTarget` is called.

## Runner

- [ ] repeat last command
- [ ] bring window to front when sending keys (if its's in the background) configurable
- [ ] store history of commands and allow selecting
- [ ] clear sequence doesn't really work, prefixing with `clear;` does
- [ ] SendCtrlD
- [ ] SendCtrlC

## Tmux

- [ ] FocusRunnerPane and optionally zoom it (might not be possible across sessions)
