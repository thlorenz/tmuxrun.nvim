local M = {}

local utils = require("tmuxrun.utils")

local import
if utils.isMain() then
	import = utils.re_require
else
	import = require
end

local selector = import("tmuxrun.selector")
local config = import("tmuxrun.config")
local conf = config.values

-- -----------------
-- Get Storage Path
-- -----------------
local function getDataDir()
	if vim.fn.has("nvim-0.3.1") == 1 then
		return vim.fn.stdpath("data")
	elseif vim.fn.has("win32") == 1 then
		return "~/AppData/Local/nvim-data/"
	else
		return "~/.local/share/nvim"
	end
end

local settingsFile = getDataDir() .. "/tmuxrun.json"

-- -----------------
-- Load/Save Settings
-- -----------------
local function getSettingsKey()
	if conf.gitProjects then
		-- try nearest git dir first since that is more likely to denote a project root
		local gitdir = vim.fn.system("git rev-parse --absolute-git-dir")
		if gitdir ~= nil then
			return string.sub(utils.trim(gitdir), 0, -6) -- cut off '/.git'
		end
	end
	return vim.fn.getcwd()
end

local function loadSettings()
	local f = io.open(settingsFile, "r")
	if f == nil then
		return {}, {}
	end
	local json = f:read("*all")
	f:close()

	local statusOk, allSettings = pcall(vim.json.decode, json)
	if not statusOk then
		vim.notify(
			"Tried to read invalid settings  from '" .. settingsFile .. "'",
			"error"
		)
		return {}, allSettings
	else
		local settingsKey = getSettingsKey()
		return allSettings[settingsKey] or {}, allSettings
	end
end

local function saveSettings(settings)
	local settingsKey = getSettingsKey()
	local _, allSettings = loadSettings()
	local updatedSettings = vim.tbl_extend(
		"force",
		allSettings,
		{ [settingsKey] = settings }
	)
	local json = vim.json.encode(updatedSettings)

	local f = io.open(settingsFile, "w")
	f:write(json)
	f:close()

	return settings
end

-- -----------------
-- Target
-- -----------------
local function encodeTarget()
	if
		selector.session == nil
		or selector.window == nil
		or selector.pane == nil
	then
		return
	end

	return selector:encodeTarget()
end

local function restoreTarget(encodedTarget)
	assert(encodedTarget ~= nil, "need encoded session target to restore")

	selector:restoreFromEncodedTarget(encodedTarget)
end

-- -----------------
-- API
-- -----------------
-- state includes everything else than the selected target
-- this state is currently maintained inside the api module
function M.save(state)
	-- using extend to make a copy of the state since we don't want to modify it as part of the save
	local settings = vim.tbl_extend("keep", state, {})

	local encodedTarget = encodeTarget()
	if encodedTarget ~= nil then
		settings.target = encodedTarget
	end

	return saveSettings(settings)
end

function M.load()
	local settings = loadSettings()
	if settings.target ~= nil then
		restoreTarget(settings.target)
	end
	return settings
end

if utils.isMain() then
	local state = { foo = 1 }
	local ext = vim.tbl_extend("keep", state, { bar = 2 })
	vim.pretty_print(state)
	vim.pretty_print(ext)
end

return M
