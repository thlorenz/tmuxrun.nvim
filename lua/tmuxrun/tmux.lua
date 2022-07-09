local M = {}

local utils = require("tmuxrun.utils")

local SEP = "&"

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
--     sessionId: string
--     name: string
--     window1: {
--       id: string
--       index: number
--       active = bool
--       panesCount = number
--     }
--     window2: { .. }
--   }
--   session2: { .. }
-- }
-- ```
-- @returns session/windows table
function M.getSessions()
	local sessions = {}

	-- Get all sessions first
	local cmd = "list-windows -a -F "
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
		.. "#{window_panes}'"

	local lines = M.getLinesForCommand(cmd)

	for _, line in pairs(lines) do
		local session, sessionId, window, windowId, windowIdx, windowActive, windowPanes =
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
					.. "(.+)$",
				line
			)
		sessions[session] = sessions[session]
			or { sessionId = sessionId, name = session }
		sessions[session][window] = {
			id = windowId,
			index = tonumber(windowIdx),
			active = windowActive == "1" and true or false,
			panesCount = tonumber(windowPanes),
		}
	end
	return sessions
end

return M
