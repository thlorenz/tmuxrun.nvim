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

return M
