function re_require(pack)
	package.loaded[pack] = nil
	return require(pack)
end

-- local require = re_require

local selector = require("tmuxrun.selector")
local tmux = require("tmuxrun.tmux")
local config = require("tmuxrun.config")

local M = { selector = selector }
local conf = config.values

-- -----------------
-- Sender
-- -----------------

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
		.. " "
		.. keys:gsub(" ", " Space ")

	return tmux.sendTmuxCommand(cmd)
end

function M.sendEnterSequence(self)
	self:_sendKeys("Enter")
end

function M.sendKeys(self, keys)
	if not self.selector:hasTarget() then
		self.selector:selectTarget()
	end

	-- TODO(thlorenz): allow user to specifty that a pane should open next to the vim pane
	if not self.selector:hasTarget() then
		return
	end

	local allKeys = conf.clearBeforeSend and conf.clearSequence .. keys or keys
	local result = self:_sendKeys(allKeys)
	if result ~= nil and result ~= "" then
		return result
	end
	return self:sendEnterSequence()
end

function M.setup(opts)
	config.setup(opts)
	return M
end

-- self = self or M
self = M.setup({})
self:sendKeys("ls -la")

return M
