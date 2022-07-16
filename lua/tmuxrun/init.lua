local config = require("tmuxrun.config")

local M = {}

function M.setup(opts)
	config.setup(opts)
	return M
end

return M
