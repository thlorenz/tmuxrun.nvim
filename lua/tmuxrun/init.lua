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
local function tmuxPanesCurrentWindow()
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

-- -----------------
-- API
-- -----------------

-- Focuses the tmux pane in which this vim session started up
function M.focusVimPane(self)
	focusTmuxPane(self.vimPane)
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
