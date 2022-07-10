local M = {
	session,
	window,
	pane,
}

local sessions = require("tmuxrun.sessions")
local tmux = require("tmuxrun.tmux")
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
		return nil
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

function M.selectPane(self, session, window)
	-- showing pane numbers only makes sense if the following is true
	-- 1. the selected window is active
	-- 2. the selected session is attached
	if sessions:isWindowActive(session.name, window.name) then
		local client = sessions:getClientForSession(session.id)
		if client ~= nil then
			local cmd = "display-panes -t " .. client.name .. " -d 800"
			tmux.sendTmuxCommand(cmd)
		end
	end
	local input = vim.fn.input("\nPane# (1.." .. window.paneCount .. "): ")
	if #input == 0 then
		return 1
	end

	local paneIdx = input:match("^(%d+)")
	if paneIdx ~= nil then
		paneIdx = tonumber(paneIdx)
		if paneIdx > window.paneCount then
			vim.notify(
				"Not a valid pane idx: "
					.. paneIdx
					.. ", defaulting to first pane",
				"warn"
			)
			return 1
		else
			return paneIdx
		end
	else
		vim.notify("Invalid idx selected, defaulting to first pane", "warn")
		return 1
	end
end

function M.selectTarget(self)
	sessions:refresh()

	local session = self:selectSession(false)
	if session == nil then
		return
	end

	local window = self:selectWindow(session)
	if window == nil then
		return
	end

	-- Got a valid session and window
	local pane = self:selectPane(session, window)
	self.session = session
	self.window = window
	self.pane = pane

	if window ~= nil then
		vim.notify(
			"Selected 'session:window'[pane] '"
				.. session.name
				.. ":"
				.. window.name
				.. "'["
				.. pane
				.. "]",
			"warn"
		)
	end
end

function M.hasTarget(self)
	return self.session ~= nil and self.window ~= nil and self.pane ~= nil
end

function M.tmuxTargetString(self)
	return self.session.name .. ":" .. self.window.name .. "." .. self.pane
end

return M
