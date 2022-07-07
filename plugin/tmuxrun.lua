if 1 ~= vim.fn.has("nvim-0.7.0") then
	vim.api.nvim_err_writeln("tmuxrun.nvim requires at least nvim-0.7.0.")
	return
end

if vim.g.loaded_tmuxrun == 1 then
	return
end
vim.g.loaded_tmuxrun = 1

vim.api.nvim_create_user_command("VVtrSendCommandToRunner", function(opts) 
  print("VtrSendCommandToRunner")
  print(vim.inspect(opts))
end, {})
