-- TODO(thlorenz): since now this module not only handles selection of the target but also
-- operations related to it it might be a good idea to to the following:
--
-- 1. pull the below into a separate state module
-- 2. have the selector module update that state when a target is selected
-- 3. have another module use that state for operations related to that target
local M = {
	session = nil,
	window = nil,
	pane = nil,
}

local utils = require("tmuxrun.utils")
local sessions = require("tmuxrun.sessions")
local tmux = require("tmuxrun.tmux")
local tmuxPane = require("tmuxrun.pane")
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

	local defaultPane = tmuxPane.defaultPane(session, window)

	local availablePanes = tmuxPane.availablePanes(session, window)

	local defaultPaneInfo
	if defaultPane == nil then
		-- when this vim session is in a window with just that one pane then we need
		-- to create a new one
		defaultPaneInfo = {
			label = tmuxPane.labelPaneSelector(1, conf.autoSplitPane),
			pane = window.panes[1],
			split = conf.autoSplitPane,
		}
	else
		defaultPaneInfo = {
			label = tmuxPane.labelPaneSelector(defaultPane.index),
			pane = defaultPane,
		}
	end

	-- panes we can use as target directly
	local paneInfos = { defaultPaneInfo }
	for _, pane in ipairs(availablePanes) do
		if pane.id ~= defaultPane.id then
			table.insert(paneInfos, {
				label = tmuxPane.labelPaneSelector(pane.index),
				pane = pane,
			})
		end
	end

	-- panes that we can split the target from
	for _, pane in ipairs(window.panes) do
		for _, split in ipairs(tmuxPane.splitInfos) do
			local dsplit = defaultPaneInfo.split
			if
				defaultPaneInfo.pane.id ~= pane.id
				or (
					dsplit == nil
					or dsplit.placement ~= split.placement
					or dsplit.direction ~= split.direction
				)
			then
				table.insert(paneInfos, {
					label = tmuxPane.labelPaneSelector(pane.index, split),
					pane = pane,
					split = split,
				})
			end
		end
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
				local paneIndex, createdNewPane = tmuxPane.processPaneSelector(
					session.name,
					window.id,
					paneInfo.pane,
					paneInfo.split
				)
				self.session = session
				self.window = window
				self.pane = paneIndex

				if createdNewPane then
					-- Get the id of the newly created pane by first refreshing sessions
					-- and finding it by current index
					sessions:refresh()
					local updatedWindow = sessions:getWindowInSessionById(
						sessions:getSessionById(session.id),
						window.id
					)
					self.pane = window.panes[paneIndex]
				else
					self.pane = paneInfo.pane
				end

				local action = createdNewPane and "Created" or "Selected"
				vim.notify(
					action
						.. " pane "
						.. session.name
						.. ":"
						.. window.name
						.. "["
						.. self.pane.index
						.. "]"
						.. "(id: "
						.. self.pane.id
						.. ")",
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

	-- TODO(thlorenz): May not need all this if we can just send to the pane by
	-- id no matter where it is
	local session = sessions:getSessionById(self.session.id)
	if session == nil then
		return false, "session"
	end

	local window = sessions:getWindowInSessionById(session, self.window.id)
	if window == nil then
		return false, "window"
	end

	local pane = sessions:getPaneInWindowById(window, self.pane.id)
	if pane == nil then
		return false, "pane"
	end

	return true
end

function M.tmuxTargetString(self, byIndex)
	if byIndex then
		return tmux.targetString(
			self.session.name,
			self.window.id,
			self.pane.index
		)
	else
		return self.pane.id
	end
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

-- -----------------
-- Tests
-- -----------------
if utils.isMain() then
	M:selectTarget()
end

return M
