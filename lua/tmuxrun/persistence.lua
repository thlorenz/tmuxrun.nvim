local M = {}

local utils = require("tmuxrun.utils")

local import
if utils.isMain() then
	import = utils.re_require
else
	import = require
end

local sessions = import("tmuxrun.sessions")
local selector = import("tmuxrun.selector")

function M.store(self, sessionId, windowId, paneId) end

function M.restore(sessionId, windowId, paneId)
	assert(sessionId ~= nil, "need sessionId to restore")
	assert(windowId ~= nil, "need windowId to restore")
	assert(paneId ~= nil, "need paneId to restore")

	selector:restoreTargetFromIds(sessionId, windowId, paneId)
end

if utils.isMain() then
	local sessionId = "$9"
	local windowId = "@58"
	local paneId = "%75"
	M.restore(sessionId, windowId, paneId)

	vim.pretty_print(selector.window)
	vim.pretty_print(selector.pane)
end

return M
