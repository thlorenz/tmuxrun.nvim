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

-- May alias to VtrAttachToPane
vim.api.nvim_create_user_command("TrSelectTarget", function(opts)
	return api.selectTarget()
end, {})
