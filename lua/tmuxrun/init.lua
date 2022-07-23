local api = require("tmuxrun.api")
local config = require("tmuxrun.config")

local M = {}

function M.setup(opts)
	config.setup(opts)
	api.loadSettings()
	return M
end

return M
