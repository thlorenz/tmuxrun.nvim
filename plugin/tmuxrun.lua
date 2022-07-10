if 1 ~= vim.fn.has("nvim-0.7.0") then
	vim.api.nvim_err_writeln("tmuxrun.nvim requires at least nvim-0.7.0.")
	return
end

if vim.g.loaded_tmuxrun == 1 then
	-- return
end
vim.g.loaded_tmuxrun = 1

local require = require("tmuxrun.utils").re_require
local api = require("tmuxrun.api")
local utils = require("tmuxrun.utils")

vim.api.nvim_create_user_command("TmuxSelectTarget", function(opts)
	api.selectTarget()
end, {})

vim.api.nvim_create_user_command("TmuxSendCommand", function(opts)
	api.sendCommand(opts.args, true)
end, { nargs = 1 })
