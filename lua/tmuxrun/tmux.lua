local SEP = "&"
local M = { SEP = SEP }

local utils = require("tmuxrun.utils")

-- Executes a command of form `tmux <command>`
function M.sendTmuxCommand(cmd)
	local prefixedCmd = "tmux " .. cmd
	local result = vim.fn.system(prefixedCmd)
	-- TODO(thlorenz): original SendTmuxcmd strips results we might have to do that as well
	return result
end

function M.getLinesForCommand(cmd)
	local output = M.sendTmuxCommand(cmd)
	return utils.splitOnNewline(output)
end

-- Builds a table of all sessions and their windows
-- Table Structure:
--
-- ```
-- {
--   session1: {
--     id: string
--     name: string
--     window1Id: {
--       id: string
--       name: string
--       index: number
--       active = bool
--       panes = { {
--          id = string
--          index = number
--          active = bool
--          historySize = bool
--         }
--       }
--     }
--     window2: { .. }
--   }
--   session2: { .. }
-- }
-- ```
-- @returns session/windows table
--
function M.getSessions()
	local sessions = {}

	-- Get all sessions first
	local cmd = "list-panes -a -F "
		.. "'#{session_name}"
		.. SEP
		.. "#{session_id}"
		.. SEP
		.. "#{window_name}"
		.. SEP
		.. "#{window_id}"
		.. SEP
		.. "#{window_index}"
		.. SEP
		.. "#{window_active}"
		.. SEP
		.. "#{pane_index}"
		.. SEP
		.. "#{pane_id}"
		.. SEP
		.. "#{pane_active}"
		.. SEP
		.. "#{history_size}'"

	local lines = M.getLinesForCommand(cmd)

	for _, line in pairs(lines) do
		local session, sessionId, window, windowId, windowIdx, windowActive, paneIndex, paneId, paneActive, historySize =
			utils.split(
				"^(.+)" -- session_name
					.. SEP
					.. "(.+)" -- session_id
					.. SEP
					.. "(.+)" -- window_name
					.. SEP
					.. "(.+)" -- window_id
					.. SEP
					.. "(.+)" -- window_index
					.. SEP
					.. "(.+)" -- window_active
					.. SEP
					.. "(.+)" -- pane_index
					.. SEP
					.. "(.+)" -- pane_id
					.. SEP
					.. "(.+)" -- pane_active
					.. SEP
					.. "(.+)", -- history_size
				line
			)
		sessions[session] = sessions[session]
			or { id = sessionId, name = session, windows = {} }
		sessions[session].windows[windowId] = sessions[session].windows[windowId]
			or {
				id = windowId,
				index = tonumber(windowIdx),
				name = window,
				active = windowActive == "1" and true or false,
				panes = {},
			}
		table.insert(sessions[session].windows[windowId].panes, {
			id = paneId,
			index = tonumber(paneIndex),
			active = paneActive == "1" and true or false,
			historySize = tonumber(historySize),
		})
	end
	return sessions
end

function M.getActiveSessionWindowPane()
	local cmd = "display-message -p '#S" .. SEP .. "#W" .. SEP .. "#P'"
	local output = M.sendTmuxCommand(cmd)
	local session, window, pane = utils.split(
		"^(.+)" .. SEP .. "(.+)" .. SEP .. "(.+)",
		utils.trim(output)
	)
	return { session = session, window = window, pane = pane }
end

function M.getActivePaneInfo()
	local cmd = "display-message -p -F "
		.. "'#{session_name}"
		.. SEP
		.. "#{session_id}"
		.. SEP
		.. "#{window_name}"
		.. SEP
		.. "#{window_id}"
		.. SEP
		.. "#{window_index}"
		.. SEP
		.. "#{pane_id}"
		.. SEP
		.. "#{pane_index}'"
	local output = M.sendTmuxCommand(cmd)
	local sessionName, sessionId, windowName, windowId, windowIndex, paneId, paneIndex =
		utils.split(
			"^(.+)"
				.. SEP
				.. "(.+)"
				.. SEP
				.. "(.+)"
				.. SEP
				.. "(.+)"
				.. SEP
				.. "(.+)"
				.. SEP
				.. "(.+)"
				.. SEP
				.. "(.+)",
			utils.trim(output)
		)
	assert(
		sessionName
			and sessionId
			and windowName
			and windowId
			and windowIndex
			and paneId
			and paneIndex,
		"should get all active pane info"
	)

	return {
		sessionName = sessionName,
		sessionId = sessionId,
		windowName = windowName,
		windowId = windowId,
		windowIndex = windowIndex,
		paneId = paneId,
		paneIndex = tonumber(paneIndex),
	}
end

function M.targetString(sessionName, windowId, pane)
	return sessionName .. ":" .. windowId .. "." .. pane
end

-- selects a window in a given session which is useful when sending a command to a session and
-- make sure that the user can see the output without having to switch to that session and
-- perform that step
function M.selectWindow(sessionId, windowId)
	local targetWindow = sessionId .. ":" .. windowId
	M.sendTmuxCommand("select-window -t '" .. targetWindow .. "'")
end

if utils.isMain() then
	vim.pretty_print(M.getSessions())
end
return M
