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
function M.selectSession(self, notifySuccess)
	local sessionNames, msg = sessions:sessionNamesAndMsg(
		self.session and self.session.name
	)

	local input = vim.fn.input(msg .. "\nSession#: ")
	if #input == 0 then
		if self.session == nil then
			vim.notify("No session selected", "warn")
		else
			if notifySuccess then
				vim.notify(
					"Kept current session '"
						.. self.session.name
						.. "' selected",
					"info"
				)
			end
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
			if notifySuccess then
				vim.notify("Selected tmux session: '" .. name .. "'", "info")
			end
			return sessions:getSessionByName(name)
		end
	else
		vim.notify("Please select a session number", "warn")
		return nil
	end
end

function M.selectWindow(self, session)
	session = session or self.session
	if session == nil then
		vim.notify("Need to select session before selecting a window", "warn")
		return
	end
	local windows, msg = sessions:windowListAndMsg(session.name)
	local input = vim.fn.input(
		"Session: " .. session.name .. "\n" .. msg .. "\nWindow#: "
	)
	if #input == 0 then
		return sessions:getActiveWindow(session.name)
	end

	local winIdx = input:match("^(%d+)")
	if winIdx ~= nil then
		winIdx = tonumber(winIdx)
		local win = windows[winIdx]
		if win == nil then
			vim.notify("Not a valid window idx: " .. winIdx, "warn")
			return nil
		end
		return win
	else
		vim.notify("Please select a window number", "warn")
		return nil
	end
end

function M.selectTarget(self, cb)
	sessions:refresh()
	local session = self:selectSession(false)
	if session ~= nil then
		self.session = session
		self.window = window

		-- deferring here only to allow session selection output to clear
		vim.defer_fn(function()
			local window = self:selectWindow(session)
			if window ~= nil then
				vim.notify(
					"Selected window '"
						.. session.name
						.. ":"
						.. window.name
						.. "'",
					"warn"
				)
				if cb ~= nil then
					cb()
				end
			end
		end, 0)
	end
end

self = self or M
self:selectTarget()

return M
