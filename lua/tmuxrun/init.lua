local persistence = require("tmuxrun.persistence")
local config = require("tmuxrun.config")

local M = {}

function M.setup(opts)
	config.setup(opts)
	persistence.load()
	return M
end

return M
