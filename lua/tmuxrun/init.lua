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
local utils = require("tmuxrun.utils")

-- @returns the selected session or nil if the user aborted or provided invalid input
function M.selectSession(self)
	-- TODO(thlorenz): Mark currently selected session which is auto-accepted if user just hits
	-- Enter
	local sessionNames, msg = sessions:sessionNamesAndMsg(
		self.session and self.session.name
	)

	local input = vim.fn.input(msg .. "\nSession#: ")
	if #input == 0 then
		if self.session == nil then
			vim.notify("No session selected", "warn")
		else
			vim.notify(
				"Kept current session '" .. self.session.name .. "' selected",
				"info"
			)
		end
		return self.session
	end
	local sessionIdx = input:match("^(%d+)")

	if sessionIdx ~= nil then
		sessionIdx = tonumber(sessionIdx)
		local name = sessionNames[sessionIdx]
		if name == nil then
			vim.notify("Not a valid session idx: " .. sessionIdx, "warn")
			return nil
		else
			vim.notify("Selected tmux session: '" .. name .. "'", "info")
			return sessions:getSessionByName(name)
		end
	else
		vim.notify("Please select a session number", "warn")
		return nil
	end
end

function M.selectWindow(self)
	if self.session == nil then
		vim.notify("Need to select session before selecting a window", "warn")
		return
	end
end

function M.selectTarget(self)
	sessions:refresh()
	local session = self:selectSession()
	if session ~= nil then
		self.session = session
		--		self:selectWindow()
	end
end

local self = M
self:selectTarget()

return M
