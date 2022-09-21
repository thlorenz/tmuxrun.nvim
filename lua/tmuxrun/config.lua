local SaveFile = {
	-- saves all files, i.e. :wa
	All = "All",
	-- saves currently activ file, i.e. :w
	Active = "Active",
	-- does not save any file
	None = "None",
}

-- these are local but may need to become globals to stay around during reloads
-- (that's how telescope.nvim does it)
local values = {
	-- clear terminal pane before sending the command keys
	clearBeforeSend = true,

	-- clear sequence to use for the above
	clearSequence = "",

	-- send Ctrl-C before sending command
	ctrlcBeforeSend = false,

	-- in which direction to create a pane when tmuxrun creates it automatically
	-- change to '{ placement = "after", direction = "horizontal" }' to split horizontally
	autoSplitPane = { placement = "after", direction = "vertical" },

	-- time in milliseconds give new terminal pane to get ready to receive commands
	-- this time is also used to wait opening a new terminal with the selected target
	newPaneInitTime = 0,

	-- ensures that the window that a command is sent to comes into view
	activateTargetWindow = true,

	-- ensures target when sending a command unless it is overriden for the particular call
	ensureTarget = true,

	-- Stores 'Up' sent via :TmuxUp as lastCommand such that :TmuxRepeatCommand will send 'Up'.
	-- Set this to false if you only want to store only commands sent via :TmuxCommand
	storeUpCommand = true,

	-- If a pane cannot be found by id, i.e. if it was closed, then tmuxrun will
	-- try to find a pane that is at the index where the one it cannot find was
	-- when it was selected as a target. That pane will be used going forward
	-- after it was promoted until it is destroyed as well at which point the
	-- next one at its index will be promoted and so on.
	-- Set this to false to turn off that behavior.
	fallbackToPaneIndex = true,

	-- if true the selected targets are persisted to disk for each project
	-- whenever a settings item like the target changes
	-- the root folder of a vim session is used to identify projects
	persistTarget = true,

	-- if true then each time a new command is executed it is persisted and loaded
	-- at startup
	persistCommand = true,

	-- if true a `.git` folder when found is considered to define a project for which settings are saved
	-- if false the current working dir `pwd` defines that project instead
	gitProjects = true,

	-- Save all or current file right before sending a command
	saveFile = SaveFile.None,
}

local config = { values = values, SaveFile = SaveFile }

function config.setValue(name, value, default)
	values[name] = value == nil and default or value
end

function config.setup(opts)
	opts = opts or {}

	config.setValue("clearBeforeSend", opts.clearBeforeSend, true)
	config.setValue("clearSequence", opts.clearSequence, "")
	config.setValue("ctrlcBeforeSend", opts.ctrlcBeforeSend, false)
	config.setValue(
		"autoSplitPane",
		opts.autoSplitPane,
		{ placement = "after", direction = "vertical" }
	)
	config.setValue("newPaneInitTime", opts.newPaneInitTime, 0)
	config.setValue("activateTargetWindow", opts.activateTargetWindow, true)
	config.setValue("ensureTarget", opts.ensureTarget, true)
	config.setValue("storeUpCommand", opts.storeUpCommand, true)
	config.setValue("fallbackToPaneIndex", opts.fallbackToPaneIndex, true)
	config.setValue("persistTarget", opts.persistTarget, true)
	config.setValue("persistCommand", opts.persistCommand, true)
	config.setValue("gitProjects", opts.gitProjects, true)
	config.setValue("saveFile", opts.saveFile, SaveFile.None)
end

return config
