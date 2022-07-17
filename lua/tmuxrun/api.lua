local api = {}

local utils = require("tmuxrun.utils")
local selector = require("tmuxrun.selector")
local runner = require("tmuxrun.runner")
local conf = require("tmuxrun.config").values

local state = {
	lastCommand = nil,
}

local function handleCommand(cmd, opts)
	if conf.activateTargetWindow then
		selector:activateCurrentWindow()
	end
	runner:sendKeys(cmd, opts)
	if opts.storeCommand then
		state.lastCommand = cmd
	end
end

function api.selectTarget(cb)
	selector:selectTarget(cb)
end

function api.unselectTarget()
	return selector:unselectTarget()
end

local function _onEnsuredTarget(cmd, createdNewPane, opts)
	assert(opts, "need to pass opts to _onEnsuredTarget")
	if createdNewPane then
		vim.defer_fn(function()
			handleCommand(cmd, opts)
		end, conf.newPaneInitTime)
	else
		handleCommand(cmd, opts)
	end
end

function api.sendCommand(cmd, opts)
	opts = opts or {}

	cmd = utils.resolveVimPathIdentifiers(cmd)

	opts.storeCommand = utils.defaultTo(opts.storeCommand, true)
	local ensureTarget = opts.ensureTarget or conf.ensureTarget

	if ensureTarget and (not selector:hasTarget()) then
		selector:selectTarget(function(createdNewPane)
			_onEnsuredTarget(cmd, createdNewPane, opts)
		end)
	else
		_onEnsuredTarget(cmd, false, opts)
	end
end

function api.sendUp(opts)
	opts = opts or {}
	opts.storeCommand = utils.defaultTo(opts.storeCommand, conf.storeUpCommand)
	api.sendCommand("Up", opts)
end

function api.repeatCommand(opts)
	if state.lastCommand == nil then
		vim.notify(
			"No commmand was sent in this session, nothing to repeat",
			"warn"
		)
		return
	end
	api.sendCommand(state.lastCommand, opts)
end

return api
