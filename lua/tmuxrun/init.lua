local M = {}

local function splitOnNewline(str)
	local lines = {}
	for s in str:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	return lines
end

local function sendTmuxCommand(command)
	local prefixedCommand = "tmux " .. command
	local result = vim.fn.system(prefixedCommand)
	-- TODO(thlorenz): original SendTmuxCommand strips results we might have to do that as well
	return result
end

local function tmuxPanes()
	local panes = sendTmuxCommand("list-panes")
	return splitOnNewline(panes)
end

local res = tmuxPanes()
print(vim.inspect(res))

return M
