local HelpText = [[
HotSwap allows objects in the game tree to be "marked", running them as plugins
when Studio's run mode is enabled.

When HotSwap is enabled and active, each marked object is treated as a Plugin
object, and all descendant Scripts are run in a plugin-like environment. As an
exception, if a marked object is a Script, it runs as a child of the Plugin
object. Note that the marked state of an object is saved with the object as a
tag.

Each running script has a 'script' and 'plugin' variable, pointing to the
current script and the current plugin, respectively. Note that all objects under
a running plugin are isolated copies that exist outside the game tree.

The HotSwap panel lists all marked objects in the current place. When active,
the current status of each plugin is displayed. A plugin can fail to run for
several reasons, such as when the plugin contains unsafe objects that throw
errors when accessed, or when a descendant cannot be copied.

HotSwap runs plugins only when enabled, and when Studio's run mode is active.
Run mode is required so that running plugins can be properly cleaned up when
they are no longer needed.
]]

return {
	Action_Add_StatusTip           = "Mark each selection as a plugin to be run by HotSwap.",
	Action_Add_Text                = "Mark Selection as Plugin",
	Action_Remove_StatusTip        = "Unmark each selection as a plugin to be run by HotSwap.",
	Action_Remove_Text             = "Unmark Selection as Plugin",
	Action_RemoveAll_StatusTip     = "Unmark all HotSwap plugins.",
	Action_RemoveAll_Text          = "Unmark All Plugins",
	Action_ToggleEnabled_StatusTip = "Toggle whether HotSwap will run marked plugins.",
	Action_ToggleEnabled_Text      = "Toggle HotSwap Enabled",
	Action_TogglePanel_StatusTip   = "Toggle the visibility of the HotSwap panel.",
	Action_TogglePanel_Text        = "Toggle HotSwap Panel",
	Button_Add_Tooltip             = "Mark each selection as a plugin.",
	Button_Changelog_Tooltip       = "Display the changelog panel.",
	Button_Help_Tooltip            = "Display the help panel.",
	Button_Remove_Tooltip          = "Unmark this plugin.",
	Button_RemoveAll_Tooltip       = "Unmark all plugins.",
	Button_ToggleEnabled_Tooltip   = "Toggle whether HotSwap is enabled when run mode is active.",
	Error_Plugin_Reserve_Limit     = "exceeded reserved plugin limit of {1:int}",
	Error_Plugin_Unclonable        = "plugin contains objects that cannot be copied",
	Error_Plugin_Unsafe            = "plugin contains unsafe objects",
	HelpPanel_Content              = HelpText,
	HelpPanel_Title                = "Help - HotSwap",
	Label_Status_Disabled_Tooltip  = "Status: disabled (HotSwap is not enabled)",
	Label_Status_Failed_Tooltip    = "Status: failed ({1})",
	Label_Status_Pending_Tooltip   = "Status: pending (plugin is not yet active)",
	Label_Status_Running_Tooltip   = "Status: running (plugin is active)",
	Panel_Title                    = "HotSwap",
	Panel_Title_Status             = "Running {1:int} plugins - HotSwap",
	Toolbar_Name                   = "HotSwap",
	Toolbar_TogglePanel_Text       = "Toggle Panel",
	Toolbar_TogglePanel_Tooltip    = "Toggle the visibility of the HotSwap panel.",
}
