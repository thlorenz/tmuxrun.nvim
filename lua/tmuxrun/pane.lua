local M = {}

local tmux = require("tmuxrun.tmux")

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
function M.processPaneSelector(sessionName, windowId, paneIdx, splitInfo)
	-- we cannot do anything if the user didn't even provide a valid pane index
	if paneIdx == nil then
		return nil, false
	end

	if splitInfo == nil then
		return paneIdx, false
	end

	if
		splitInfo.placement == "after"
		and splitInfo.direction == "horizontal"
	then
		return M.splitHorizontal(sessionName, windowId, paneIdx), true
	end
	if splitInfo.placement == "after" and splitInfo.direction == "vertical" then
		return M.splitVertical(sessionName, windowId, paneIdx), true
	end

	-- all remaining splits are 'before'
	if splitInfo.direction == "horizontal" then
		return M.splitHorizontalBefore(sessionName, windowId, paneIdx), true
	end
	if splitInfo.direction == "vertical" then
		return M.splitVerticalBefore(sessionName, windowId, paneIdx), true
	end

	-- This should NEVER happen unless the autoSplitPane configuration is invalid
	assert(
		false,
		"'"
			.. vim.inspect(split)
			.. "'"
			.. "has an invalid direction '"
			.. splitInfo.direction
			.. "'"
	)
end

function M.labelPaneSelector(paneIndex, splitInfo)
	if splitInfo == nil then
		return "Select Pane: " .. paneIndex
	else
		return "Split "
			.. splitInfo.placement
			.. " Pane "
			.. paneIndex
			.. " "
			.. splitInfo.direction
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

-- @returns allPaneIndexes, availablePaneIndexes
--   - allPaneIndexes are all panes that exist in the window and that we can
--      split relative to in order to create a target
--   - availablePaneIndexes are all panes that could be a target
function M.availablePaneIndexes(session, window)
	local active = tmux.getActivePaneInfo()
	local allPaneIndexes = {}
	local availablePaneIndexes = {}
	for i = 1, window.paneCount do
		table.insert(allPaneIndexes, i)
		if active.paneIndex ~= i then
			table.insert(availablePaneIndexes, i)
		end
	end
	return allPaneIndexes, availablePaneIndexes
end

return M
