local selector = require("tmuxrun.selector")
local tmux = require("tmuxrun.tmux")
local config = require("tmuxrun.config")
local conf = config.values

local M = { selector = selector }

-- Adds a pane to target with a command via the `-t` flag
local function targetedTmuxCommand(command, targetPane)
	return command .. " -t " .. targetPane
end

function M._sendKeys(self, keys)
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

function M.sendEnterSequence(self)
	self:_sendKeys("Enter")
end

function M.sendKeys(self, keys)
	-- TODO(thlorenz): allow user to specify that a pane should open next to the vim pane
	if not self.selector:hasTarget() then
		vim.notify(
			"Tried to send keys to tmux, but haven't set a target yet, via ':TmuxSelectTarget'",
			"warn"
		)
		return
	end

	local allKeys = conf.clearBeforeSend and conf.clearSequence .. " " .. keys
		or keys
	local result = self:_sendKeys(keys)
	if result ~= nil and result ~= "" then
		return result
	end
	return self:sendEnterSequence()
end

return M
