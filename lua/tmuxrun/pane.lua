local M = {}

-- split-window [-bdfhIvPZ] [-c start-directory] [-e environment] [-l size] [-t
--         target-pane] [shell-command] [-F format]
--               (alias: splitw)
--         Create a new pane by splitting target-pane: -h does a horizontal split and -v a
--         vertical split; if neither is specified, -v is assumed.  The -l option specifies
--         the size of the new pane in lines (for vertical split) or in columns (for hori-
--         zontal split); size may be followed by `%' to specify a percentage of the avail-
--         able space.  The -b option causes the new pane to be created to the left of or
--         above target-pane.  The -f option creates a new pane spanning the full window
--         height (with -h) or full window width (with -v), instead of splitting the active
--         pane.  -Z zooms if the window is not zoomed, or keeps it zoomed if already
--         zoomed.

local tmux = require("tmuxrun.tmux")
local paneSelectorRx = "^%s*(%d+)([hvHV]?)"

-- TODO(thlorenz): The newly crated pane keeps focus, we need to switch it
-- back to our vim pane
local function split(sessionName, windowName, pane, direction, before)
	local beforeFlag = before and " -b" or ""
	local target = tmux.targetString(sessionName, windowName, pane)
	local cmd = "split-window"
		.. " -t "
		.. target
		.. " -"
		.. direction
		.. beforeFlag
	tmux.sendTmuxCommand(cmd)
end

function M.splitVertical(sessionName, windowName, pane)
	split(sessionName, windowName, pane, "v", false)
	return pane + 1
end

function M.splitHorizontal(sessionName, windowName, pane)
	split(sessionName, windowName, pane, "h", false)
	return pane + 1
end

function M.splitVerticalBefore(sessionName, windowName, pane)
	split(sessionName, windowName, pane, "v", true)
	return pane
end

function M.splitHorizontalBefore(sessionName, windowName, pane)
	split(sessionName, windowName, pane, "h", true)
	return pane
end

-- This matches user input expressing how to select and/or split a pane.
-- The following three options exist (n being a pane idx):
-- - "n" returns n
-- - "nv" splits a pane vertically after n and returns n+1
-- - "nh" splits a pane vertically after n and returns n+1
-- - "nV" splits a pane vertically before n and returns n
-- - "nH" splits a pane vertically before n and returns n
-- @returns the selected pane index and if a new pane was created
function M.processPaneSelector(sessionName, windowName, input)
	local paneIdx, direction = input:match(paneSelectorRx)

	-- we cannot do anything if the user didn't even provide a valid pane index
	if paneIdx == nil then
		return nil, false
	end

	paneIdx = tonumber(paneIdx)
	if direction == nil or direction == "" then
		return paneIdx, false
	end

	-- user provided `<num>h` or `<num>v` which means split a new pane after the index
	if direction == "h" then
		return M.splitHorizontal(sessionName, windowName, paneIdx), true
	end
	if direction == "v" then
		return M.splitVertical(sessionName, windowName, paneIdx), true
	end

	-- user provided `<num>H` or `<num>V` which means split a new pane before the index
	if direction == "H" then
		return M.splitHorizontalBefore(sessionName, windowName, paneIdx), true
	end
	if directio == "V" then
		return M.splitVerticalBefore(sessionName, windowName, paneIdx), true
	end

	-- This should NEVER happen unless your's truly screwed up
	assert(
		false,
		"'"
			.. input
			.. "'"
			.. "matched the regex but had an invalid direction '"
			.. direction
			.. "'"
	)
end

return M
