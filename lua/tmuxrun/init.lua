function re_require(pack)
	package.loaded[pack] = nil
	return require(pack)
end

-- local require = re_require

local api = require("tmuxrun.api")
local config = require("tmuxrun.config")
local conf = config.values

local M = {}

function M.setup(opts)
	config.setup(opts)
	return M
end

return M
