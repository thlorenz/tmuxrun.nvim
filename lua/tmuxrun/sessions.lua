local M = {
	sessions = {},
}

local utils = require("tmuxrun.utils")
local tmux = require("tmuxrun.tmux")

function M.refresh(self)
	self.sessions = tmux.getSessions()
end

function M.getSessions(self)
	return self.sessions
end

function M.getActiveWindows(self)
	local sessions = {}
	for session, windows in pairs(self.sessions) do
		for name, win in pairs(windows) do
			if win.active then
				sessions[session] = vim.tbl_extend(
					"force",
					win,
					{ name = name }
				)
			end
		end
	end
	return sessions
end

function M.getSessionNames(self)
	local names = {}
	for session, _ in pairs(self.sessions) do
		table.insert(names, session)
	end
	return names
end

function M.printSessionNames(self)
	local sessionNames = self:getSessionNames()
	local str = table.concat(sessionNames, ", ")
	print(str)
end

function M.sessionNamesAndMsg(self)
	local sessionNames = self:getSessionNames()
	table.sort(sessionNames)
	local msg = "Sessions:\n" .. "---------\n"
	for idx, name in pairs(sessionNames) do
		local idxStr = "" .. idx
		local padded = (" "):rep(3 - #idxStr) .. idxStr
		msg = msg .. padded .. ": " .. name .. "\n"
	end
	return sessionNames, msg
end

return M
