local selector = require("tmuxrun.selector")
local tmux = require("tmuxrun.tmux")
local config = require("tmuxrun.config")
local conf = config.values

local M = { selector = selector }

function M._sendKeys(self, keys, opts)
	assert(
		self.selector:hasTarget(),
		"should have selected session, window and pane"
	)
	local cmd = "send-keys -t "
		.. self.selector:tmuxTargetString()
		.. ' "'
		.. keys:gsub('"', '\\"')
		.. '"'

	return tmux.sendTmuxCommand(cmd)
end

function M._sendClearSequence(self)
	self:_sendKeys(conf.clearSequence)
end

function M._sendEnterSequence(self)
	self:_sendKeys("Enter")
end

function M.sendKeys(self, keys)
	if not self.selector:hasTarget() then
		vim.notify(
			"Tried to send keys to tmux, but haven't set a target yet, via ':TmuxSelectTarget'",
			"warn"
		)
		return
	end

	local isTargetValid, missing = self.selector:verifyTarget()
	if not isTargetValid then
		local missingDetails
		if "session" == missing then
			missingDetails = "Session '" .. self.selector.session.name .. "'"
		elseif "window" == missing then
			missingDetails = "Window '"
				.. self.selector.window.name
				.. "'"
				.. " inside session '"
				.. self.selector.session.name
				.. "'"
		elseif "pane" == missing then
			missingDetails = "Pane '"
				.. self.selector.pane
				.. "'"
				.. " of window '"
				.. self.selector.window.name
				.. "'"
				.. " inside session '"
				.. self.selector.session.name
				.. "'"
		end
		vim.notify(missingDetails .. " cannot be found.", "warn")
		vim.notify("Set a new target via: TmuxSelectTarget", "info")
	end

	if conf.clearBeforeSend then
		self:_sendClearSequence()
	end

	local result = self:_sendKeys(keys, opts)
	if result ~= nil and result ~= "" then
		return result
	end
	return self:_sendEnterSequence()
end

return M
