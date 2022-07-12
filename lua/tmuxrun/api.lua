local api = {}

local selector = require("tmuxrun.selector")
local runner = require("tmuxrun.runner")
local conf = require("tmuxrun.config").values

local state = {
	lastCommand = nil,
}

local function handleCommand(cmd)
	runner:sendKeys(cmd)
	state.lastCommand = cmd
end

function api.selectTarget()
	return selector:selectTarget()
end

function api.unselectTarget()
	return selector:unselectTarget()
end

function api.sendCommand(cmd, ensureTarget)
	-- allow non-neovim tools to espress bool via int
	if ensureTarget == 1 then
		ensureTarget = true
	end
	if ensureTarget == 0 then
		ensureTarget = false
	end

	local createdNewPane = false
	if ensureTarget and (not selector:hasTarget()) then
		createdNewPane = selector:selectTarget()
	end
	if createdNewPane then
		vim.defer_fn(function()
			handleCommand(cmd)
		end, conf.newPaneInitTime)
	else
		handleCommand(cmd)
	end
end

function api.repeatCommand(ensureTarget)
	if state.lastCommand == nil then
		vim.notify(
			"No commmand was sent in this session, nothing to repeat",
			"warn"
		)
		return
	end
	api.sendCommand(state.lastCommand, ensureTarget)
end

return api
