local M = {
	session,
	window,
	pane,
}

local sessions = require("tmuxrun.sessions")
local tmux = require("tmuxrun.tmux")
local utils = require("tmuxrun.utils")
local processPaneSelector = require("tmuxrun.pane").processPaneSelector
local conf = require("tmuxrun.config").values

-- @returns the selected session or nil if the user aborted or provided invalid input
function M.selectSession(self, notifySuccess)
	local active = tmux.getActiveSessionWindowPane()

	local sessionNames, msg = sessions:sessionNamesAndMsg(
		(self.session and self.session.name) or active.session
	)

	local input = vim.fn.input(msg .. "\nSession#: ")
	if #input == 0 then
		if self.session == nil then
			if active.session == nil then
				vim.notify("No session selected", "warn")
			else
				local session = sessions:getSessionByName(active.session)
				-- fill in the input for the user
				print(session.name)
				self.session = session
			end
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
	local input = vim.fn.input("\n" .. msg .. "\nWindow#: ")
	if #input == 0 then
		local window = sessions:getActiveWindow(session.name)
		-- complete input for user
		print(window.name)
		return window
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

local function defaultPaneNumberAndPanesInput(session, window)
	-- If user selected the same session and window that the vim instance is running in then
	-- we don't want to ruse the pane a that it occupies.
	-- Instead we look up if we have more than one pane and if so return any pane
	-- that is not the vim pane.
	local active = tmux.getActiveSessionWindowPane()
	local defaultPaneNumber
	if
		session.name ~= active.session
		and window.name ~= active.window
		and active.pane ~= 1
	then
		defaultPaneNumber = 1
	elseif window.paneCount > 1 then
		defaultPaneNumber = 2
	end

	local panes = ""
	for i = 1, window.paneCount do
		local marker = (defaultPaneNumber == i and "*") or " "
		local comma = i == 1 and "" or ", "
		panes = panes .. comma .. marker .. i
	end

	return defaultPaneNumber, panes
end

local function maybeDisplayPanes(session, window)
	-- showing pane numbers only makes sense if the following is true
	-- 1. the selected window is active
	-- 2. the selected session is attached
	if sessions:isWindowActive(session.name, window.name) then
		local client = sessions:getClientForSession(session.id)
		if client ~= nil then
			local cmd = "display-panes -t " .. client.name .. " -N -b -d 5000"
			vim.defer_fn(function()
				tmux.sendTmuxCommand(cmd)
			end, 0)
		end
	end
end

function M.selectPane(self, session, window)
	maybeDisplayPanes(session, window)

	local defaultPaneNumber, panes = defaultPaneNumberAndPanesInput(
		session,
		window
	)

	local ixPreselected = defaultPaneNumber
			and "- press enter to pane" .. defaultPaneNumber
		or "- press enter to add a new pane"

	local ixs = [[

Panes:
------
]] .. ixPreselected .. [[

- select existing pane, i.e. 1
- or create new pane as follows 
  - 1h splits it horizontally after pane 1
  - 2v splits it vertically after pane 3
  - 3H splits it horizontally before pane 3
  - 2V splits it vertically before pane 2
  ]]
	local input = vim.fn.input(ixs .. "\n[" .. panes .. "]: ")
	if #input == 0 then
		if defaultPaneNumber ~= nil then
			return defaultPaneNumber, false
		else
			return processPaneSelector(
				session.name,
				window.name,
				1 .. conf.autoCreatedPaneDirection
			),
				true
		end
	end

	-- TODO(thlorenz): handle invalid inputs like <non-existent-pane>v with a warning
	local paneIdx, createdNewPane = processPaneSelector(
		session.name,
		window.name,
		input
	)
	if paneIdx ~= nil then
		if not createdNewPane and paneIdx > window.paneCount then
			vim.notify(
				"Not a valid pane idx: " .. paneIdx .. ", defaulting pane",
				"warn"
			)
			return defaultPaneNumber or 1, createdNewPane
		else
			return paneIdx, createdNewPane
		end
	else
		vim.notify("Invalid idx selected, defaulting to first pane", "warn")
		return defaultPaneNumber or 1, createdNewPane
	end
end

function M.selectTarget(self)
	sessions:refresh()

	local session = self:selectSession(false)
	if session == nil then
		return false
	end

	local window = self:selectWindow(session)
	if window == nil then
		return false
	end

	-- Got a valid session and window
	local selectedPane, createdNewPane = self:selectPane(session, window)
	self.session = session
	self.window = window
	self.pane = selectedPane

	if window ~= nil then
		local action = createdNewPane and "Created" or "Selected"
		vim.notify(
			action
				.. " 'session:window'[pane] '"
				.. session.name
				.. ":"
				.. window.name
				.. "'["
				.. selectedPane
				.. "]",
			"warn"
		)
	end
	return createdNewPane
end

function M.hasTarget(self)
	return self.session ~= nil and self.window ~= nil and self.pane ~= nil
end

function M.tmuxTargetString(self)
	return tmux.targetString(self.session.name, self.window.name, self.pane)
end

return M
