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

function M.sessionNamesAndMsg(self, currentlySelectedSessionName)
	local sessionNames = self:getSessionNames()
	table.sort(sessionNames)
	local msg = "\nSessions:\n" .. "---------\n"
	for idx, name in pairs(sessionNames) do
		local selectedIndicator = " "
		if name == currentlySelectedSessionName then
			selectedIndicator = "*"
		end
		local idxStr = "" .. idx
		local padded = selectedIndicator .. (" "):rep(3 - #idxStr) .. idxStr
		msg = msg .. padded .. ": " .. name .. "\n"
	end
	return sessionNames, msg
end

function M.getSessionAtIdx(self, idx)
	return self.sessions[idx]
end

function M.getSessionByName(self, name)
	return self.sessions[name]
end

function M.getSessionById(self, id)
	for _, session in pairs(self.sessions) do
		if session.id == id then
			return session
		end
	end
end

-- M:refresh()
-- local session = M:getSessionByName("lua")
-- utils.dump(session)

return M
