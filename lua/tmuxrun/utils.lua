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

function M.trimEnd(s)
	return s:gsub("(.-)%s*$", "%1")
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

local pathIdentifierRx1 = "(%%:[phtre]:[phtre]:[phtre]:[phtre]:[phtre])"
local pathIdentifierRx2 = "(%%:[phtre]:[phtre]:[phtre]:[phtre])"
local pathIdentifierRx3 = "(%%:[phtre]:[phtre]:[phtre])"
local pathIdentifierRx4 = "(%%:[phtre]:[phtre])"
local pathIdentifierRx5 = "(%%:[phtre])"
local pathIdentifierRx6 = "(%%)"
local pathIdentifierRx7 = "(#)"

function M.resolveVimPathIdentifiers(cmd)
	cmd = cmd .. " "
	cmd = cmd:gsub(pathIdentifierRx1, vim.fn.expand)
	cmd = cmd:gsub(pathIdentifierRx2, vim.fn.expand)
	cmd = cmd:gsub(pathIdentifierRx3, vim.fn.expand)
	cmd = cmd:gsub(pathIdentifierRx4, vim.fn.expand)
	cmd = cmd:gsub(pathIdentifierRx5, vim.fn.expand)
	cmd = cmd:gsub(pathIdentifierRx6, vim.fn.expand)
	cmd = cmd:gsub(pathIdentifierRx7, vim.fn.expand)
	return M.trimEnd(cmd)
end

function M.isMain()
	return not pcall(debug.getlocal, 4, 1)
end

-- -----------------
-- Tests
-- -----------------
if M.isMain() then
	print(
		M.resolveVimPathIdentifiers("echo testing % && luajit % --test") .. "'"
	)

	print(M.resolveVimPathIdentifiers("luajit %:p") .. "'")
	print(M.resolveVimPathIdentifiers("luajit # --other-flag") .. "'")

	print(
		M.resolveVimPathIdentifiers(
			"echo testing %:p:t && echo extension: %:p:e --test"
		) .. "'"
	)
end

return M
