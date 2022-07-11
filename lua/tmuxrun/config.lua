-- these are local but may need to become globals to stay around during reloads
-- (that's how telescope.nvim does it)

local values = {
	clearBeforeSend = true,
	clearSequence = "",
	autoCreatedPaneDirection = "v", -- or "h"
}
local config = { values = values }

function config.setValue(name, value, default)
	values[name] = value == nil and default or value
end

function config.setup(opts)
	opts = opts or {}

	config.setValue("clearBeforeSend", opts.clearBeforeSend, true)
	config.setValue("clearSequence", opts.clearSequence, "")
	config.setValue(
		"autoCreatedPaneDirection",
		opts.autoCreatedPaneDirection,
		"v"
	)
	return self
end

return config
