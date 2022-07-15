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

-- @returns the selected pane index and if a new pane was created
function M.processPaneSelector(sessionName, windowId, paneIdx, split)
	-- we cannot do anything if the user didn't even provide a valid pane index
	if paneIdx == nil then
		return nil, false
	end

	if split == nil then
		return paneIdx, false
	end

	if split.placement == "after" and split.direction == "horizontal" then
		return M.splitHorizontal(sessionName, windowId, paneIdx), true
	end
	if split.placement == "after" and split.direction == "vertical" then
		return M.splitVertical(sessionName, windowId, paneIdx), true
	end

	-- all remaining splits are 'before'
	if split.direction == "horizontal" then
		return M.splitHorizontalBefore(sessionName, windowId, paneIdx), true
	end
	if split.direction == "vertical" then
		return M.splitVerticalBefore(sessionName, windowId, paneIdx), true
	end

	-- This should NEVER happen unless the autoSplitPane configuration is invalid
	assert(
		false,
		"'"
			.. vim.inspect(split)
			.. "'"
			.. "has an invalid direction '"
			.. split.direction
			.. "'"
	)
end

function M.labelPaneSelector(paneIndex, split)
	if split == nil then
		return "Select Pane: " .. paneIndex
	else
		return "Split "
			.. split.placement
			.. " Pane "
			.. paneIndex
			.. " "
			.. split.direction
			.. "ly"
	end
end

M.splitInfos = {
	{ placement = "after", direction = "horizontal" },
	{ placement = "after", direction = "vertical" },
	{ placement = "before", direction = "horizontal" },
	{ placement = "before", direction = "vertical" },
}

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
		return 1, false
	elseif window.paneCount > 1 then
		return 2, true
	else
		return nil, true
	end
end

return M
