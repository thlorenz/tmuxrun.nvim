local api = require("tmuxrun.api")
local config = require("tmuxrun.config")
local conf = config.values

local M = {}

function M.setup(opts)
	config.setup(opts)
	return M
end

return M
