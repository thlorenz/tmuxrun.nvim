local api = {}

local utils = require("tmuxrun.utils")
local selector = require("tmuxrun.selector")
local runner = require("tmuxrun.runner")
local persistence = require("tmuxrun.persistence")

local config = require("tmuxrun.config")
local conf = config.values

local state = {
	lastCommand = nil,
}

local function handleCommand(cmd, opts)
	if conf.activateTargetWindow then
		selector:activateCurrentWindow()
	end
	runner:sendKeys(cmd, opts)
	if opts.storeCommand then
		if cmd ~= state.lastCommand then
			state.lastCommand = cmd
			-- saving settings only if command changed which should be fine since we expect
			-- the same commmand to be repeated much more in which case we don't persist
			if conf.persistCommand then
				api.saveSettings()
			end
		end
	end
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

function api.selectTarget(cb)
	selector:selectTarget(function(...)
		if conf.persistTarget then
			api.saveSettings()
		end
		if cb ~= nil then
			cb(...)
		end
	end)
end

function api.unselectTarget()
	selector:unselectTarget()

	if conf.persistTarget then
		api.saveSettings()
	end
end

function api.sendCommand(cmd, opts)
	opts = opts or {}

	-- optionally save active or all files before sending command
	if conf.saveFile == config.SaveFile.All then
		vim.api.nvim_command("wa")
	elseif conf.saveFile == config.SaveFile.Active then
		vim.api.nvim_command("w")
	end

	cmd = utils.resolveVimPathIdentifiers(cmd)

	opts.storeCommand = utils.defaultTo(opts.storeCommand, true)
	local ensureTarget = opts.ensureTarget or conf.ensureTarget

	if ensureTarget and (not selector:hasTarget()) then
		api.selectTarget(function(createdNewPane)
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

-- This is not exposed via a command since it happens automatically,
-- for instance whenever a new target is selected.
-- However if a user wants to call this then they can.
function api.saveSettings()
	persistence.save(state)
end

-- This isn't exposed either as it is invoked as part of tmuxrun.setup (see ./init.lua)
function api.loadSettings()
	local loadedSettings = persistence.load()
	if conf.persistCommand and loadedSettings.lastCommand ~= nil then
		state.lastCommand = loadedSettings.lastCommand
	end
end

function api.showConfig()
	vim.pretty_print(conf)
end

return api
