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

function M.dump(obj)
	print(vim.inspect(obj))
end

return M
