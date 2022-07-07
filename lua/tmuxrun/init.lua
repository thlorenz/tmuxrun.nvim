local M = {
	vimPane = nil,
	runnerPane = nil,
}

-- -----------------
-- Utils
-- -----------------
-- Adds a pane to target with a command via the `-t` flag
local function targetedTmuxCommand(command, targetPane)
	return command .. " -t " .. targetPane
end

local function splitOnNewline(str)
	local lines = {}
	for s in str:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	return lines
end

-- Executes a command of form `tmux <command>`
local function sendTmuxCommand(command)
	local prefixedCommand = "tmux " .. command
	local result = vim.fn.system(prefixedCommand)
	-- TODO(thlorenz): original SendTmuxCommand strips results we might have to do that as well
	return result
end

local function focusTmuxPane(paneNumber)
	local targetedCmd = targetedTmuxCommand("select-pane", paneNumber)
	sendTmuxCommand(targetedCmd)
end

local function activePaneIndex()
	return sendTmuxCommand('display-message -p "#{pane_index}"')
end

-- @returns list of tmux panes of the current window
local function tmuxPanes()
	local panes = sendTmuxCommand("list-panes")
	return splitOnNewline(panes)
end

local windowPatternRx = "^(%d+): ([-_a-zA-Z]+)[-* ]"

function windowMap()
	local windowMap = {}
	local result = sendTmuxCommand("list-windows")
	local lines = splitOnNewline(result)
	for _, line in pairs(lines) do
		print(line)
		local n, label = line:match(windowPatternRx)
		print(n, label)
		if n ~= nil and label ~= nil then
			table.insert(windowMap, n, label)
		end
	end
	return windowMap
end

local paneIndexRx = "^(%d+): "
-- @returns all indices of the panes of the current window
local function paneIndices()
	local indices = {}
	local panes = tmuxPanes()
	for _, pane in pairs(panes) do
		local index = pane:match(paneIndexRx)
		if index ~= nil then
			table.insert(indices, index, index)
		end
	end
	return indices
end

-- @param pane - the pane index we're looking for
-- @returns true if the specified pane index is found in the current window
local function desiredPaneExists(pane)
	local indices = paneIndices()
	return indices[pane] ~= nil
end

local function tmuxInfo(message)
	-- TODO: this should accept optional target pane, default to current.
	-- Pass that to TargetedCommand as "display-message", "-p '#{...}')
	return sendTmuxCommand("display-message -p '#{" .. message .. "}'")
end

-- TODO(thlorenz): CONTINUE HERE
local layout = tmuxInfo("window_layout")

print(layout)

local function currentMajorOrientation()
	-- let orientation_map = { '[': 'v', '{': 'h' }
	-- let layout = tmuxInfo('window_layout')
	-- let outermost_orientation = substitute(layout, '[^[{]', '', 'g')[0]
	-- return orientation_map[outermost_orientation]
end

-- -----------------
-- API
-- -----------------

-- Focuses the tmux pane in which this vim session started up
function M.focusVimPane(self)
	focusTmuxPane(self.vimPane)
end

-- @param pane - the pane number we want to use for the runner
-- @returns true if the provided pane does not exist yet
function M.validRunnerPaneNumber(self, pane)
	self.vimPane = activePaneIndex()

	if pane == self.vimPane then
		return false
	end
	if desiredPaneExists(pane) then
		return false
	end
	return true
end

function M.attachToSpecifiedPane(self, pane)
	if self:validRunnerPaneNumber(pane) then
		self.runnerPane = pane
		self.vimPane = activePaneIndex()
		vim.notify("Runner pane set to: " .. pane, "info")
		-- TODO(thlorenz): orientation
	else
		vim.notify("Invalid pane number: " .. pane, "warn")
	end
end

-- Kill the tmux pane to which the tmux runner was attached
function M.killLocalRunner()
	-- TODO(thlorenz):
end

function M.init(self)
	self.vimPane = activePaneIndex()
end

M:init()

return M
