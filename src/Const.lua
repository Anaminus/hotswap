return {
	-- Tag is used with CollectionService to mark an object as a plugin.
	Tag = "\27~hotswap#",
	-- ID contains identifiers that must be unique in the Studio namespace.
	ID = {
		ToolbarTogglePanel  = "HotSwap_Toolbar_TogglePanel",
		ActionTogglePanel   = "HotSwap_Action_TogglePanel",
		ActionToggleEnabled = "HotSwap_Action_ToggleEnabled",
		ActionAdd           = "HotSwap_Action_Add",
		ActionRemove        = "HotSwap_Action_Remove",
		ActionRemoveAll     = "HotSwap_Action_RemoveAll",
		Panel               = "HotSwap_Panel"
	},
	-- Setting contains identifiers for plugin settings.
	Setting = {
		Enabled = "HotSwap_Enabled",
	},
	GUI = {
		Size = 20,
		Spacing = 4,
		Padding = 2,
		ScrollWidth = 16,
	},
	-- ReservedPlugins determines the number of reserved Plugin objects. Studio
	-- has a bug where it freezes if Plugin objects are created after the
	-- calling thread has yielded. To work around this, HotSwap creates and
	-- reserves a number of Plugin objects before yielding, at the cost of
	-- limiting the number of runnable plugins. If ReservedPlugins is nil or 0,
	-- then no Plugins are reserved, and instead are created as needed.
	ReservedPlugins = 4,
	Debug = true,
}
