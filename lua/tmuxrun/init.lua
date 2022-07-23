local api = require("tmuxrun.api")
local config = require("tmuxrun.config")

local M = {}

M.SaveFile = config.SaveFile

function M.setup(opts)
	config.setup(opts)
	api.loadSettings()
	return M
end

return M
