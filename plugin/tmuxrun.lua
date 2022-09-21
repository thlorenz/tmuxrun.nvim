if 1 ~= vim.fn.has("nvim-0.7.0") then
	vim.api.nvim_err_writeln("tmuxrun.nvim requires at least nvim-0.7.0.")
	return
end

if vim.g.loaded_tmuxrun == 1 then
	return
end
vim.g.loaded_tmuxrun = 1 -- luacheck:ignore 122

local api = require("tmuxrun.api")

vim.api.nvim_create_user_command("TmuxSelectTarget", function()
	api.selectTarget()
end, {})

vim.api.nvim_create_user_command("TmuxUnselectTarget", function()
	api.unselectTarget()
end, {})

vim.api.nvim_create_user_command("TmuxCommand", function(opts)
	api.sendCommand(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("TmuxUp", function()
	api.sendUp()
end, {})

vim.api.nvim_create_user_command("TmuxCtrlC", function()
	api.sendCtrlC()
end, {})

vim.api.nvim_create_user_command("TmuxCtrlD", function()
	api.sendCtrlD()
end, {})

vim.api.nvim_create_user_command("TmuxRepeatCommand", function()
	api.repeatCommand()
end, {})

vim.api.nvim_create_user_command("TmuxConfig", function()
	api.showConfig()
end, {})

vim.api.nvim_create_user_command("TmuxZoom", function()
	api.toggleZoom()
end, {})

vim.api.nvim_create_user_command("TmuxFace", function(opts)
	api.faceTarget()
	if opts.bang then
		api.toggleZoom()
	end
end, { bang = true })
