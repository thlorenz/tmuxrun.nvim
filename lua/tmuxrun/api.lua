local api = {}

local selector = require("tmuxrun.selector")

function api.selectTarget()
	return selector:selectTarget()
end

return api
