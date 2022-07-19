local M = {}

local utils = require("tmuxrun.utils")

local import
if utils.isMain() then
	import = utils.re_require
else
	import = require
end

local selector = import("tmuxrun.selector")

function M.store()
	-- TODO(thlorenz): use the below to store
	if
		selector.session == nil
		or selector.window == nil
		or selector.pane == nil
	then
		return
	end

	local encodedTarget = selector:encodeTarget()
	print(encodedTarget)
	return encodedTarget
end

function M.restore(encodedTarget)
	assert(encodedTarget ~= nil, "need encoded session target to restore")

	selector:restoreFromEncodedTarget(encodedTarget)
	vim.pretty_print(selector.pane)
end

if utils.isMain() then
	local encodedTarget = "$9" .. "&" .. "@58" .. "&" .. "%75"
	M.restore(encodedTarget)
end

return M
