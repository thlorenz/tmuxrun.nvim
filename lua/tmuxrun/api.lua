local api = {}

local selector = require("tmuxrun.selector")
local runner = require("tmuxrun.runner")
local conf = require("tmuxrun.config").values

function api.selectTarget()
	return selector:selectTarget()
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
			runner:sendKeys(cmd)
		end, conf.newPaneInitTime)
	else
		runner:sendKeys(cmd)
	end
end

return api
