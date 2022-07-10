local api = {}

local selector = require("tmuxrun.selector")
local runner = require("tmuxrun.runner")

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

	if ensureTarget and (not selector:hasTarget()) then
		selector:selectTarget()
	end
	runner:sendKeys(cmd)
end

return api
