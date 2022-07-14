local M = {}

function M.re_require(pack)
	package.loaded[pack] = nil
	return require(pack)
end

function M.splitToList(rx, str)
	local parts = {}
	for s in str:gmatch(rx) do
		table.insert(parts, s)
	end
	return parts
end

function M.splitOnNewline(str)
	return M.splitToList("[^\r\n]+", str)
end

function M.split(rx, str)
	return str:match(rx)
end

function M.padWith(padTarget, minLen, filler)
	filler = filler or " "
	return (filler):rep(minLen - #padTarget) .. padTarget
end

function M.dump(obj)
	print(vim.inspect(obj))
end

function M.trim(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

function M.moveListItem(list, itemToMove, targetIdx)
	local itemIdx
	for idx, item in ipairs(list) do
		if item == itemToMove then
			itemIdx = idx
		end
	end

	table.remove(list, itemIdx)
	table.insert(list, targetIdx, itemToMove)
end

function M.defaultTo(val, default)
	return val == nil and default or val
end

-- lua patterns aren't really regexes and thus don't support the | operator 🤯
local BEFORE = "(.*%s)"
local AFTER = "(%s?.*)"
local pathIdentifierRx1 = BEFORE .. "(%%:[phtre])" .. AFTER
local pathIdentifierRx2 = BEFORE .. "(%%)" .. AFTER
local pathIdentifierRx3 = BEFORE .. "(#)" .. AFTER

function M.resolveVimPathIdentifiers(cmd)
	-- TODO(thlorenz): use gmatch here in order to replace multiple occurrences if use cases
	-- arise
	local bef, pathId, aft = cmd:match(pathIdentifierRx1)
	if bef == nil then
		bef, pathId, aft = cmd:match(pathIdentifierRx2)
	end
	if bef == nil then
		bef, pathId, aft = cmd:match(pathIdentifierRx3)
	end
	if bef == nil then
		return cmd
	end
	return bef .. vim.fn.expand(pathId) .. aft
end

return M
