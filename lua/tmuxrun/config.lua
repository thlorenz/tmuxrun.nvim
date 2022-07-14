-- these are local but may need to become globals to stay around during reloads
-- (that's how telescope.nvim does it)

local values = {
	-- clear terminal pane before sending the command keys
	clearBeforeSend = true,
	-- clear sequence to use for the above
	clearSequence = "",
	-- in which direction to create a pane when tmuxrun creates it automatically
	autoCreatedPaneDirection = "v", -- or "h"
	-- time in milliseconds give new terminal pane to get ready to receive commands
	newPaneInitTime = 0,
	-- ensures that the window that a command is sent to comes into view
	activateTargetWindow = true,
	-- ensures target when sending a command unless it is overriden for the particular call
	ensureTarget = true,
	-- Stores 'Up' sent via :TmuxUp as lastCommand such that :TmuxRepeatCommand will send 'Up'.
	-- Set this to false if you only want to store only commands sent via :TmuxCommand
	storeUpCommand = true,
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
	config.setValue("newPaneInitTime", opts.newPaneInitTime, 0)
	config.setValue("activateTargetWindow", opts.activateTargetWindow, true)
	config.setValue("ensureTarget", opts.ensureTarget, true)
	config.setValue("storeUpCommand", opts.storeUpCommand, true)
	return self
end

return config
