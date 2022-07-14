local M = {}

local tmux = require("tmuxrun.tmux")
local paneSelectorRx = "^%s*(%d+)([hvHV]?)"

local function split(sessionName, windowId, pane, direction, before)
	local beforeFlag = before and " -b" or ""
	local target = tmux.targetString(sessionName, windowId, pane)
	local cmd = "split-window -d"
		.. " -t "
		.. target
		.. " -"
		.. direction
		.. beforeFlag
	tmux.sendTmuxCommand(cmd)
end

function M.splitVertical(sessionName, windowId, pane)
	split(sessionName, windowId, pane, "v", false)
	return pane + 1
end

function M.splitHorizontal(sessionName, windowId, pane)
	split(sessionName, windowId, pane, "h", false)
	return pane + 1
end

function M.splitVerticalBefore(sessionName, windowId, pane)
	split(sessionName, windowId, pane, "v", true)
	return pane
end

function M.splitHorizontalBefore(sessionName, windowId, pane)
	split(sessionName, windowId, pane, "h", true)
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
function M.processPaneSelector(sessionName, windowId, selector)
	local paneIdx, direction = selector:match(paneSelectorRx)

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
		return M.splitHorizontal(sessionName, windowId, paneIdx), true
	end
	if direction == "v" then
		return M.splitVertical(sessionName, windowId, paneIdx), true
	end

	-- user provided `<num>H` or `<num>V` which means split a new pane before the index
	if direction == "H" then
		return M.splitHorizontalBefore(sessionName, windowId, paneIdx), true
	end
	if direction == "V" then
		return M.splitVerticalBefore(sessionName, windowId, paneIdx), true
	end

	-- This should NEVER happen unless your's truly screwed up
	assert(
		false,
		"'"
			.. selector
			.. "'"
			.. "matched the regex but had an invalid direction '"
			.. direction
			.. "'"
	)
end

-- If user selected the same session and window that the vim instance is running in then
-- we don't want to re-use the pane a that it occupies.
-- Instead we look up if we have more than one pane and if so return any pane
-- that is not the vim pane.
-- If there is only one pane and it is our vim session then it returns nil.
function M.defaultPaneIndex(session, window)
	local active = tmux.getActivePaneInfo()
	local defaultPaneNumber
	if
		session.id ~= active.sessionId
		or window.id ~= active.windowId
		or active.paneIndex ~= 1
	then
		return 1
	elseif window.paneCount > 1 then
		return 2
	else
		return nil
	end
end

return M
