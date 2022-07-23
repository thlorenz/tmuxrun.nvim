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
	for sessionName, session in pairs(self.sessions) do
		for _, win in pairs(session.windows) do
			if win.active then
				sessions[sessionName] = win
			end
		end
	end
	return sessions
end

function M.getSessionNames(self)
	local names = {}
	for key, _ in pairs(self.sessions) do
		table.insert(names, key)
	end
	return names
end

function M.getSessionList(self)
	local list = {}
	for _, session in pairs(self.sessions) do
		table.insert(list, session)
	end
	return list
end

function M.sortedSessions(self, comparator)
	if self.sessions ~= nil then
		local list = self:getSessionList()
		table.sort(list, comparator)
		return list
	else
		return nil
	end
end

function M.sortedSessionsByName(self)
	return self:sortedSessions(function(a, b)
		return a.name < b.name
	end)
end

function M.printSessionNames(self)
	local sessionNames = self:getSessionNames()
	local str = table.concat(sessionNames, ", ")
	print(str)
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

-- -----------------
-- Windows
-- -----------------
function M.sortedWindows(self, sessionName, comparator)
	local session = self.sessions[sessionName]
	if session == nil then
		return nil
	end

	if session.windows ~= nil then
		local list = {}
		for _, window in pairs(session.windows) do
			table.insert(list, window)
		end
		table.sort(list, comparator)
		return list
	else
		return nil
	end
end

function M.sortedWindowsByIndex(self, sessionName)
	return self:sortedWindows(sessionName, function(a, b)
		return a.index < b.index
	end)
end

function M.sortedWindowsByName(self, sessionName)
	return self:sortedWindows(sessionName, function(a, b)
		return a.name < b.name
	end)
end

-- Looks for the active window of the provided session
--
-- @throws Assertion Error if either the session isn't found or it has no
-- active window.
-- @returns active window of the session
function M.getActiveWindow(self, sessionName)
	local session = self.sessions[sessionName]
	assert(session, "Session '" .. sessionName .. "' not found")
	for _, win in pairs(session.windows) do
		if win.active then
			return win
		end
	end
	assert(false, "Each session should have an active window")
end

function M.isWindowActive(self, sessionName, windowId)
	local activeWindow = self:getActiveWindow(sessionName)
	return activeWindow.id == windowId
end

function M.getWindowInSessionById(self, session, windowId)
	for _, win in pairs(session.windows) do
		if win.id == windowId then
			return win
		end
	end
end

-- -----------------
-- Panes
-- -----------------
function M.getPaneInWindowById(self, window, paneId)
	for _, pane in pairs(window.panes) do
		if pane.id == paneId then
			return pane
		end
	end
end

function M.getSessionWindowPaneById(self, sessionId, windowId, paneId)
	local session = self:getSessionById(sessionId)
	if session == nil then
		return nil, nil, nil
	end

	local window = session.windows[windowId]
	if window == nil then
		return session, nil, nil
	end

	local pane = self:getPaneInWindowById(window, paneId)
	return session, window, pane
end

-- -----------------
-- Clients
-- -----------------
function M.getClients(self)
	local clients = {}
	local cmd = 'list-clients -F "#{client_name}'
		.. tmux.SEP
		.. '#{session_id}"'
	local output = tmux.sendTmuxCommand(cmd)
	local lines = utils.splitOnNewline(output)
	for _, line in pairs(lines) do
		local clientName, sessionId = utils.split(
			"(.+)" .. tmux.SEP .. "(.+)",
			line
		)
		local session = self:getSessionById(sessionId)
		local client = { name = clientName, session = session }
		table.insert(clients, client)
	end
	return clients
end

function M.getClientForSession(self, sessionId)
	local clients = self:getClients()
	for _, client in pairs(clients) do
		if client.session.id == sessionId then
			return client
		end
	end
end

return M
