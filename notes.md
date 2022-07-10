# Useful Commands

## Sessions

- [post](https://koenwoortman.com/tmux-list-sessions/)

### List all Tmux sessions

```
tmux list-sessions
```

```
# Show only active windows
tmux ls -F "#{session_name}&#{window_name}"
```

## Windows

### List all Windows of a particular Tmux session

     list-windows [-a] [-F format] [-f filter] [-t target-session]
                   (alias: lsw)
             If -a is given, list all windows on the server.  Otherwise, list
             windows in the current session or in target-session.  -F speci-
             fies the format of each line and -f a filter.  Only windows for
             which the filter is true are shown.  See the FORMATS section.

```
tmux list-windows -t twitch+tmux-runner
```

### List all Windows across all Sessions

```
tmux list-windows -a -F "#{session_name}&#{window_name}"
```

### Select Window


    select-window [-lnpT] [-t target-window]

                  (alias: selectw)
            Select the window at target-window.  -l, -n and -p are equivalent
            to the last-window, next-window and previous-window commands.  If
            -T is given and the selected window is already the current win-
            dow, the command behaves like last-window.

Works across sessions but really only selects in the same session.

```
tmux select-window -t <window_name>
```

## Panes

### List all panes of a particular window of the Current Session

     list-panes [-as] [-F format] [-f filter] [-t target]
                   (alias: lsp)
             If -a is given, target is ignored and all panes on the server are
             listed.  If -s is given, target is a session (or the current ses-
             sion).  If neither is given, target is a window (or the current
             window).  -F specifies the format of each line and -f a filter.
             Only panes for which the filter is true are shown.  See the
             FORMATS section.

This works from other windows in the same session.

```
tmux list-panes -t telescope 
```

### Show all Panes across Sessions and Windows

```
tmux list-panes -a -F "#{session_name}&#{window_name}"
```

### Show numbers in all panes of current window

```
tmux display-panes
# For particular client via -t
tmux display-panes -t /dev/ttys001 
# -d overrides duration (ms)
```

### Select Pane

    select-pane [-DdeLlMmRUZ] [-T title] [-t target-pane]
                  (alias: selectp)
            Make pane target-pane the active pane in its window.  If one of
            -D, -L, -R, or -U is used, respectively the pane below, to the
            left, to the right, or above the target pane is used.  -Z keeps
            the window zoomed if it was zoomed.  -l is the same as using the
            last-pane command.  -e enables or -d disables input to the pane.
            -T sets the pane title.

            -m and -M are used to set and clear the marked pane.  There is
            one marked pane at a time, setting a new marked pane clears the
            last.  The marked pane is the default target for -s to join-pane,
            move-pane, swap-pane and swap-window.

# Wiki Links

- [tmux formats](https://github.com/tmux/tmux/wiki/Formats)
