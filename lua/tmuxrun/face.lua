local M = {}

local utils = require("tmuxrun.utils")
local conf = require("tmuxrun.config").values

local function runCmd(cmd)
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
						"Opening target session in a new window of current terminal failed "
							.. vim.inspect(j:result())
					)
				end
			end,
		})
		:start()
end

local function openTerminalCmd(sessionId)
	return [[
  tell application "Terminal"
    do script "tmux attach-session -t ]] .. sessionId .. [["
  end tell

  tell application "System Events" to tell process "Terminal"
    set value of attribute "AXFullScreen" of window 1 to true
  end tell

  delay ]] .. math.max(conf.newPaneInitTime / 1000, 0.400) .. [[

  tell application "System Events"
    key code 36
  end tell
]]
end

local function openITermCmd(sessionId)
	-- Note: that we only wait half the pane init time here since full-screening iTerm
	-- takes some time already
	return [[
  tell application "iTerm2"
    set newWindow to (create window with default profile)

    tell current session of newWindow
      write text "tmux attach-session -t ]] .. sessionId .. [["
    end tell
  end tell

  tell application "System Events" to tell process "iTerm2"
    set value of attribute "AXFullScreen" of window 1 to true
  end tell
  delay ]] .. math.max(conf.newPaneInitTime / 2000, 0.200) .. [[

  tell application "System Events"
    key code 36
  end tell
]]
end

function M.openTerm(sessionId)
	local openITerm = openITermCmd(sessionId)
	local openTerminal = openTerminalCmd(sessionId)
	local cmd = [[
tell application "System Events"
  set activeApp to name of first application process whose frontmost is true
  if "iTerm2" is in activeApp then
]] .. openITerm .. [[
  else if "Terminal" is in activeApp then
]] .. openTerminal .. [[
  end if
end tell
]]
	runCmd(cmd)
end

if utils.isMain() then
	M.openTerm("nvim")
end

return M
