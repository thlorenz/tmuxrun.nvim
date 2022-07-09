local M = {
	vimSession,
	vimWindow,
	vimPane,
	session,
	window,
	pane,
}

function re_require(pack)
	package.loaded[pack] = nil
	return require(pack)
end

local require = re_require
local sessions = require("tmuxrun.sessions")

function M.selectSession(self)
	local sessionNames, msg = sessions:sessionNamesAndMsg()

	local input = vim.fn.input(msg .. "\nSession #: ")
	if #input == 0 then
		return
	end
	local sessionIdx = input:match("^(%d+)")

	if sessionIdx ~= nil then
		sessionIdx = tonumber(sessionIdx)
		local name = sessionNames[sessionIdx]
		if name == nil then
			vim.notify("Not a valid session idx: " .. sessionIdx, "warn")
		else
			self.session = name
			vim.notify("Selected tmux session: " .. name, "info")
		end
	else
		vim.notify("Please select a session number", "warn")
	end
end

M:selectSession()

return M
