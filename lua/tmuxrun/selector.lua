-- TODO(thlorenz): since now this module not only handles selection of the target but also
-- operations related to it it might be a good idea to to the following:
--
-- 1. pull the below into a separate state module
-- 2. have the selector module update that state when a target is selected
-- 3. have another module use that state for operations related to that target
local M = {
	session,
	window,
	pane,
}

local utils = require("tmuxrun.utils")
local sessions = require("tmuxrun.sessions")
local tmux = require("tmuxrun.tmux")
local pane = require("tmuxrun.pane")
local processPaneSelector = require("tmuxrun.pane").processPaneSelector
local conf = require("tmuxrun.config").values

-- -----------------
-- Helpers
-- -----------------
local function maybeDisplayPanes(session, window)
	-- showing pane numbers only makes sense if the following is true
	-- 1. the selected window is active
	-- 2. the selected session is attached
	if sessions:isWindowActive(session.name, window.id) then
		local client = sessions:getClientForSession(session.id)
		if client ~= nil then
			local cmd = "display-panes -t " .. client.name .. " -N -b -d 5000"
			vim.defer_fn(function()
				tmux.sendTmuxCommand(cmd)
			end, 0)
		end
	end
end

-- -----------------
-- Selecting a Target
-- -----------------

-- calls back with the selected session or nil if the user aborted or provided invalid input
function M.selectSession(self, cb)
	local sortedSessions = sessions:sortedSessionsByName()

	local defaultSession
	if self.session ~= nil then
		defaultSession = self.session
	else
		local activeSessionName = tmux.getActiveSessionWindowPane().session
		assert(activeSessionName, "there should always be an active session")
		defaultSession = sessions:getSessionByName(activeSessionName)
	end
	assert(defaultSession, "should have found a default session")

	utils.moveListItem(sortedSessions, defaultSession, 1)

	vim.ui.select(sortedSessions, {
		prompt = "Select Session",
		kind = "tmuxrun/sessions",
		format_item = function(session)
			return session.name
		end,
	}, function(session)
		cb(session or defaultSession)
	end)
end

function M.selectWindow(self, session, cb)
	assert(session, "Need to select session before selecting a window")

	local sortedWindows = sessions:sortedWindowsByIndex(session.name)
	local defaultWindow = sessions:getActiveWindow(session.name)
	utils.moveListItem(sortedWindows, defaultWindow, 1)

	vim.ui.select(sortedWindows, {
		prompt = "Select Window",
		kind = "tmuxrun/windows",
		format_item = function(window)
			return window.index .. ":" .. window.name
		end,
	}, function(window)
		cb(window or defaultWindow)
	end)
end

function M.selectPane(self, session, window, cb)
	assert(session, "Need to select session before selecting a window")
	assert(window, "Need to select window before selecting a pane")

	local defaultPaneIndex = pane.defaultPaneIndex(session, window)
	-- TODO(thlorenz): handle case where defaultPaneIndex is nil
	local defaultPaneInfo = {
		label = "Select Pane: " .. defaultPaneIndex,
		selector = "" .. defaultPaneIndex,
	}
	local paneInfos = { defaultPaneInfo }
	for i = #paneInfos, window.paneCount do
		if i ~= defaultPaneIndex then
			table.insert(paneInfos, {
				label = "Select Pane: " .. i,
				selector = "" .. i,
			})
		end
	end

	-- TODO(thlorenz): the selector being a string that has to be matched with a
	-- regex further on is mainly due to how this involved. When we have some
	-- time we should refactor this into a proper data type instead,
	-- i.e. selector = { pane = i, split = 'vertical' | 'horizontal' | nil }
	for i = 1, #paneInfos do
		table.insert(paneInfos, {
			label = "Split before Pane " .. i .. " vertically",
			selector = i .. "V",
		})
		table.insert(paneInfos, {
			label = "Split before Pane " .. i .. " horizontally",
			selector = i .. "H",
		})
		table.insert(paneInfos, {
			label = "Split after  Pane " .. i .. " vertically",
			selector = i .. "v",
		})
		table.insert(paneInfos, {
			label = "Split after  Pane " .. i .. " horizontally",
			selector = i .. "h",
		})
	end

	-- work around for ui.select text is not showing until a key is pressed after
	-- the pane numbers are displayed
	vim.defer_fn(function()
		maybeDisplayPanes(session, window)
	end, 200)

	vim.ui.select(paneInfos, {
		prompt = "Select Pane",
		kind = "tmuxrun/panes",
		format_item = function(paneInfo)
			return paneInfo.label
		end,
	}, function(paneInfo)
		cb(paneInfo or defaultPaneInfo)
	end)
end

function M.selectTarget(self, cb)
	sessions:refresh()
	self:selectSession(function(session)
		self:selectWindow(session, function(window)
			if session == nil then
				-- We don't know what to do if the user decided to either abort the
				-- selection or selected an invalid session, better to just stop the whole operation
				--
				-- NOTE: that the existing settings aren't updated until a complete
				--       valid selection has been made of session, window and pane
				return
			end
			if window == nil then
				-- As for an invalid session, there isn't much we can do here, thus we
				-- just get out of the way
				return
			end
			self:selectPane(session, window, function(paneInfo)
				local paneIndex, createdNewPane = pane.processPaneSelector(
					session.name,
					window.id,
					paneInfo.selector
				)
				self.session = session
				self.window = window
				self.pane = paneIndex

				local action = createdNewPane and "Created" or "Selected"
				vim.notify(
					action
						.. " pane "
						.. session.name
						.. ":"
						.. window.name
						.. "["
						.. paneIndex
						.. "]",
					"info"
				)

				-- TODO(thlorenz): Evaluate if we could just store and return the pane info
				-- including the pane id in order to send keys to it directly (not even
				-- needing session and window)
				-- - disadvantage: if the pane is removed and another one created in
				--   same position then that would no longer work
				-- - advantage: if the pane is moved and/or other panes created before
				--   it then it will still find the correct pane
				-- - combining the two might be the best solution, i.e. verifying that
				--   the pane with the specified id still exists and if not
				--   auto-selecting the one that has the same index in the window
				if cb ~= nil then
					cb(createdNewPane)
				end
			end)
		end)
	end)
end

function M.unselectTarget(self)
	self.session = nil
	self.window = nil
	self.pane = nil
end

-- -----------------
-- Queries
-- -----------------

function M.hasTarget(self)
	return self.session ~= nil and self.window ~= nil and self.pane ~= nil
end

function M.verifyTarget(self)
	assert(
		self.session ~= nil and self.window ~= nil and self.pane ~= nil,
		"should not call verify target if no complete target was selected"
	)
	sessions:refresh()
	local session = sessions:getSessionById(self.session.id)
	if session == nil then
		return false, "session"
	end

	local window = sessions:getWindowInSessionById(session, self.window.id)
	if window == nil then
		return false, "window"
	end

	if window.paneCount < self.pane then
		return false, "pane"
	end

	return true
end

function M.tmuxTargetString(self)
	return tmux.targetString(self.session.name, self.window.id, self.pane)
end

-- -----------------
-- Operations on already selected target
-- -----------------
function M.activateCurrentWindow(self)
	assert(
		self:hasTarget(),
		"should not try to activate current window unless a target was set"
	)
	tmux.selectWindow(self.session.id, self.window.id)
end

return M
