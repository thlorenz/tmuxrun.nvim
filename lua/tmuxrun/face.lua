local M = {}

local utils = require("tmuxrun.utils")

local function runCmd(cmd, app)
	local status_ok, plenary = pcall(require, "plenary")
	if not status_ok then
		vim.notify(
			"Failed to load plenary which is required for the tmux plugin to support openeing iTerm or Terminal",
			"error"
		)
		return
	end

	plenary.Job
		:new({
			command = "osascript",
			args = { "-e", cmd },
			on_exit = function(j, return_val)
				if return_val ~= 0 then
					vim.notify(
						"Opening in session in "
							.. app
							.. " failed "
							.. vim.inspect(j:result())
					)
				end
			end,
		})
		:start()
end

function M.openTerminal(sessionId)
	local cmd = [[
  tell application "Terminal"
    do script "tmux attach-session -t ]] .. sessionId .. [["
  end tell

  tell application "System Events" to tell process "Terminal"
    set value of attribute "AXFullScreen" of window 1 to true
  end tell

  delay 0.800 
  tell application "System Events"
    key code 36
  end tell ]]

	runCmd(cmd, "Terminal")
end

function M.openITerm(sessionId)
	local cmd = [[
tell application "iTerm2"
  set newWindow to (create window with default profile)

  tell current session of newWindow
    write text "tmux attach-session -t ]] .. sessionId .. [["
  end tell
end tell

tell application "System Events" to tell process "iTerm2"
  set value of attribute "AXFullScreen" of window 1 to true
end tell
delay 0.400
tell application "System Events"
  key code 36
end tell
]]
	runCmd(cmd, "iTerm")
end

if utils.isMain() then
	M.openITerm("nvim")
end

return M
