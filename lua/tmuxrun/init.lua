local M = {
	vimPane = nil,
	runnerPane = nil,
	runnerOrientation = nil,
	initialCommand = nil,
	runnerPercentage = nil,

	gitCdUpOnOpen = nil,
	clearBeforeSend = nil,
	prompt = nil,
	useVtrMaps = nil,
	clearOnReorient = nil,
	clearOnReattach = nil,
	detachedName = nil,
	clearSequence = nil,
	displayPaneNumbers = nil,
	stripLeadingWhitespace = nil,
	clearEmptyLines = nil,
	appendNewline = nil,

	deferSendKeysForNewRunner = nil,
}

-- -----------------
-- Tmux Utils
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
	return tonumber(sendTmuxCommand('display-message -p "#{pane_index}"'))
end

-- @returns list of tmux panes of the current window
local function tmuxPanes()
	local panes = sendTmuxCommand("list-panes")
	return splitOnNewline(panes)
end

local windowPatternRx = "^(%d+): ([-_a-zA-Z]+)[-* ]"

-- @returns a list of all tmux windows with the key being the index and the
-- value the window label
function windowMap()
	local windowMap = {}
	local result = sendTmuxCommand("list-windows")
	local lines = splitOnNewline(result)
	for _, line in pairs(lines) do
		local n, label = line:match(windowPatternRx)
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

local function currentMajorOrientation()
	local layout = tmuxInfo("window_layout")
	local bracketsAndBracesOnlyOnly = layout:gsub("[^[{]", "")
	local outerMostOrientation = bracketsAndBracesOnlyOnly:sub(0, 1)
	-- TODO(thlorenz): the original code does not account for the last (nil)
	-- case which occurs when there is only one pane in the current window
	return outerMostOrientation == "{" and "v"
		or outerMostOrientation == "[" and "h"
		or nil
end

-- -----------------
-- API
-- -----------------

-- Focuses the tmux pane in which this vim session started up
function M.focusVimPane(self)
	focusTmuxPane(self.vimPane)
end

function M._sendKeys(self, keys)
	local targetedCmd = targetedTmuxCommand("send-keys", self.runnerPane)
	local fullCmd = (targetedCmd .. " " .. keys:gsub(" ", " Space "))
	return sendTmuxCommand(fullCmd)
end

function M.sendEnterSequence(self)
	self:_sendKeys("Enter")
end

function M.sendKeys(self, keys)
	local cmd = self.clearBeforeSend and self.clearSequence .. keys or keys
	local result = self:_sendKeys(cmd)
	if result ~= nil and result ~= "" then
		return result
	end
	return self:sendEnterSequence()
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

function M.toggleOrientationVariable(self)
	-- TODO(thlorenz): this doesn't account either for the case where the current
	-- value is nil (see todo in currentMajorOrientation)
	self.runnerOrientation = (self.runnerOrientation == "v" and "h" or "v")
end

-- @returns true if the current runner pane is valid, otherwise it notifies an
-- error
function validRunnerPaneSet(self)
	if self.runnerPane == nil then
		vim.notify("No runner pane attached.", "error")
		return false
	end
	if self.validRunnerPaneNumber(self.runnerPane) then
		vim.notify(
			"Runner pane setting ("
				.. self.runnerPane
				.. ") is invalid. Please reattach.",
			"error"
		)
		return false
	end
	return true
end

-- Tries to set the runner pane to the specified pane after checkint that that
-- pane does ont exist yet
-- It also refreshes the vimPane and the runnerOrientation
function M.attachToSpecifiedPane(self, pane)
	if self:validRunnerPaneNumber(pane) then
		self.runnerPane = pane
		self.vimPane = activePaneIndex()
		vim.notify("Runner pane set to: " .. pane, "info")
		self.runnerOrientation = currentMajorOrientation()
	else
		vim.notify("Invalid pane number: " .. pane, "warn")
	end
end

-- Kill the tmux pane to which the tmux runner was attached
function M.killLocalRunner()
	-- TODO(thlorenz):
end

function M.createRunnerPane(self, config)
	if config ~= nil then
		self.runnerOrientation = config.orientation or self.runnerOrientation
		self.runnerPercentage = config.percentage or self.runnerPercentage
		self.initialCommand = config.cmd or self.initialCommand
	end

	self.vimPane = activePaneIndex()

	local cmd = "split-window -p "
		.. self.runnerPercentage
		.. " -"
		.. self.runnerOrientation
	local result = sendTmuxCommand(cmd)
	if result ~= nil and result ~= "" then
		vim.notify("Failed to create runner pane (" .. result .. ")", "error")
	end

	self.runnerPane = activePaneIndex()
	self:focusVimPane()

	if self.gitCdUpOnOpen then
		-- TODO(thlorenz): need gitCdUp
		self:gitCdUp()
	end

	if self.initialCommand ~= nil and self.initialCommand ~= "" then
		vim.defer_fn(function()
			assert(not self:sendKeys(self.initialCommand))
		end, self.deferSendKeysForNewRunner)
	end
end

function M.currentSettings(self)
	return {
		vimPane = self.vimPane,
		runnerPane = self.runnerPane,
		runnerOrientation = self.runnerOrientation,
		runnerPercentage = self.runnerPercentage,
		initialCommand = self.initialCommand,
		gitCdUpOnOpen = self.gitCdUpOnOpen,
		clearBeforeSend = self.clearBeforeSend,
		prompt = self.prompt,
		useVtrMaps = self.useVtrMaps,
		clearOnReorient = self.clearOnReorient,
		clearOnReattach = self.clearOnReattach,
		detachedName = self.detachedName,
		clearSequence = self.clearSequence,
		displayPaneNumbers = self.displayPaneNumbers,
		stripLeadingWhitespace = self.stripLeadingWhitespace,
		clearEmptyLines = self.clearEmptyLines,
		appendNewline = self.appendNewline,
	}
end

function M.dumpCurrentSettings(self)
	print(vim.inspect(self:currentSettings()))
end
function M.noteCurrentSettings(self)
	vim.notify(vim.inspect(self:currentSettings()), "info")
end

function M.initSetting(self, name, value, default)
	self[name] = value == nil and default or value
end

function M.init(self, config)
	config = config or {}
	self.vimPane = activePaneIndex()

	self:initSetting("runnerPercentage", config.runnerPercentage, 20)
	self:initSetting("runnerOrientation", config.runnerOrientation, "v")
	self:initSetting("initialCommand", config.initialCommand, "")
	self:initSetting("gitCdUpOnOpen", config.gitCdUpOnOpen, false)
	self:initSetting("clearBeforeSend", config.clearBeforeSend, true)
	self:initSetting("prompt", config.prompt, "Command to run: ")
	self:initSetting("useVtrMaps", config.useVtrMaps, false)
	self:initSetting("clearOnReorient", config.clearOnReorient, true)
	self:initSetting("clearOnReattach", config.clearOnReattach, true)
	self:initSetting("detachedName", config.detachedName, "VTR_Pane")
	self:initSetting("clearSequence", config.clearSequence, "")
	self:initSetting("displayPaneNumbers", config.displayPaneNumbers, true)
	self:initSetting(
		"stripLeadingWhitespace",
		config.stripLeadingWhitespace,
		true
	)
	self:initSetting("clearEmptyLines", config.clearEmptyLines, true)
	self:initSetting("appendNewline", config.appendNewline, false)
	self:initSetting(
		"deferSendKeysForNewRunner",
		config.deferSendKeysForNewRunner,
		0
	)
end

M:init({ initialCommand = "ls -la", deferSendKeysForNewRunner = 600 })
-- M:noteCurrentSettings()
M:createRunnerPane()

return M
