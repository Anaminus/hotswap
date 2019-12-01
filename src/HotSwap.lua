local plugin = script.Parent
local Const = require(plugin.Const)
local Lion = require(plugin.Lion)

local CollectionService = game:GetService("CollectionService")

-- A plugin consists of an instance tree, where the root is a Plugin object.
-- When marking a selection as a plugin, each object is treated as the root of a
-- plugin tree. That is, when HotSwap is active, each object is virtually
-- transformed into a Plugin object, and, like plugins, all descendant Scripts
-- are run.

-- HotSwap is active only when enabled, and when Studio's run mode is active.
-- Run mode is required so that hotswapped plugins that are no longer needed can
-- be properly cleaned up.

local enabled = plugin:GetSetting(Const.Setting.Enabled)
local HotSwap = {
	monitorConn = nil,
	active = game:GetService("RunService"):IsRunMode(),
	enabled = enabled == nil and true or not not enabled,
	enabledChanged = Instance.new("BindableEvent"),
	pluginAdded = Instance.new("BindableEvent"),
	pluginRemoved = Instance.new("BindableEvent"),
	pluginStatus = Instance.new("BindableEvent"),
}

-- Reserve a number of Plugin objects *now*; Studio freezes if these are created
-- after yielding.
local reservedPlugins
if HotSwap.active and type(Const.ReservedPlugins) == "number" and Const.ReservedPlugins > 0 then
	reservedPlugins = {}
	for i = 1, Const.ReservedPlugins do
		table.insert(reservedPlugins, PluginManager():CreatePlugin())
	end
end

function HotSwap:IsUnsafe(object)
	local ok, result = pcall(function()
		return object.RobloxLocked
	end)
	return not ok or result
end

HotSwap.PluginAdded = HotSwap.pluginAdded.Event
HotSwap.PluginRemoved = HotSwap.pluginRemoved.Event
HotSwap.PluginStatus = HotSwap.pluginStatus.Event
HotSwap.EnabledChanged = HotSwap.enabledChanged.Event

CollectionService:GetInstanceAddedSignal(Const.Tag):Connect(function(plugin)
	if HotSwap:IsUnsafe(plugin) then
		return
	end
	HotSwap.pluginAdded:Fire(plugin)
end)
CollectionService:GetInstanceRemovedSignal(Const.Tag):Connect(function(plugin)
	if HotSwap:IsUnsafe(plugin) then
		return
	end
	HotSwap.pluginRemoved:Fire(plugin)
end)

function HotSwap:runPlugin(realPlugin)
	if self:IsUnsafe(realPlugin) then
		return
	end

	for _, descendant in pairs(realPlugin:GetDescendants()) do
		if self:IsUnsafe(descendant) or Const.Debug and descendant.Name == "DEBUG_UNSAFE" then
			-- Disallow plugins that contain unsafe objects.
			self.pluginStatus:Fire(realPlugin, false, Lion.Error_Plugin_Unsafe())
			return
		end
	end

	-- Create a standalone copy of the plugin tree for use by running scripts. A
	-- running thread can't tell the difference between the real and working
	-- copies.
	local workingChildren = realPlugin:GetChildren()
	for i, realChild in pairs(workingChildren) do
		local archivable = realChild.Archivable
		local ok, workingChild = pcall(function()
			realChild.Archivable = true
			local copy = realChild:Clone()
			realChild.Archivable = archivable
			copy.Archivable = archivable
			return copy
		end)
		if not ok or not workingChild or Const.Debug and realChild.Name == "DEBUG_UNCLONABLE" then
			-- Disallow plugins that contain unclonable objects.
			self.pluginStatus:Fire(realPlugin, false, Lion.Error_Plugin_Unclonable())
			return
		end
		workingChildren[i] = workingChild
	end

	local workingPlugin
	if reservedPlugins then
		workingPlugin = table.remove(reservedPlugins)
		if workingPlugin == nil then
			self.pluginStatus:Fire(realPlugin, false, Lion.Error_Plugin_Reserve_Limit({Const.ReservedPlugins}))
			return
		end
	else
		workingPlugin = PluginManager():CreatePlugin()
	end
	workingPlugin.Name = "Plugin_" .. realPlugin:GetFullName()
	for _, workingChild in pairs(workingChildren) do
		workingChild.Parent = workingPlugin
	end

	-- Create a copy of the plugin tree containing the actual running scripts.
	-- This contains only ModuleScripts and stand-in objects representing their
	-- ancestors, for the purpose of producing correct full names for error
	-- messages and stack traces.
	local virtualScripts = {}
	local virtualPlugin = Instance.new("Folder")
	virtualPlugin.Name = workingPlugin.name
	for _, workingScript in pairs(workingPlugin:GetDescendants()) do
		if workingScript:IsA("Script") then
			local workingAncestors = {}
			local workingParent = workingScript.Parent
			while workingParent and workingParent ~= workingPlugin do
				table.insert(workingAncestors, workingParent)
				workingParent = workingParent.Parent
			end

			-- Find/create virtual ancestors so that virtualScript:GetFullName()
			-- matches workingScript:GetFullName().
			local virtualParent = virtualPlugin
			for i = #workingAncestors, 1, -1 do
				local name = workingAncestors[i].Name
				local virtualObject = virtualParent:FindFirstChild(name)
				if virtualObject == nil then
					virtualObject = Instance.new("Folder")
					virtualObject.Name = name
					virtualObject.Parent = virtualParent
				end
				virtualParent = virtualObject
			end

			-- Actual script where the code runs.
			local virtualScript = Instance.new("ModuleScript")
			virtualScript.Name = workingScript.Name
			-- Wrap in a function call so that global variables can be passed
			-- in. The preamble sets the global variables of the ModuleScript,
			-- so that things like `getfenv(1).script` return the correct value.
			-- Start actual source on same line so that line numbers are
			-- correct.
			virtualScript.Source = "return function(s,p)script,plugin,s,p=s,p,nil,nil;" .. workingScript.Source .. "\nend"
			virtualScript.Parent = virtualParent

			table.insert(virtualScripts, {
				virtual = virtualScript,
				working = workingScript,
			})
		end
	end

	for _, data in pairs(virtualScripts) do
		-- Run via signal so that stack traces are displayed correctly.
		local signal = Instance.new("BindableEvent")
		signal.Event:Connect(function(script, plugin)
			require(data.virtual)(script, plugin)
		end)
		signal:Fire(data.working, workingPlugin)
	end
	-- Report success.
	self.pluginStatus:Fire(realPlugin, true)
end

function HotSwap:Enabled()
	return self.enabled
end

function HotSwap:SetEnabled(enabled)
	self.enabled = not not enabled
	plugin:SetSetting(Const.Setting.Enabled, self.enabled)
	self.enabledChanged:Fire(self.enabled)
end

function HotSwap:Active()
	return self.active
end

function HotSwap:ListPlugins()
	local list = CollectionService:GetTagged(Const.Tag)
	for i = #list, 1, -1 do
		if self:IsUnsafe(list[i]) then
			table.remove(list, i)
		end
	end
	return list
end

function HotSwap:AddPlugin(plugin)
	if HotSwap:Active() or self:IsUnsafe(plugin) then
		return
	end
	CollectionService:AddTag(plugin, Const.Tag)
end

function HotSwap:RemovePlugin(plugin)
	if HotSwap:Active() then
		return
	end
	CollectionService:RemoveTag(plugin, Const.Tag)
end

function HotSwap:RemoveAllPlugins()
	if HotSwap:Active() then
		return
	end
	for _, plugin in pairs(CollectionService:GetTagged(Const.Tag)) do
		CollectionService:RemoveTag(plugin, Const.Tag)
	end
end

function HotSwap:StartMonitoring()
	self.monitorConn = CollectionService:GetInstanceAddedSignal(Const.Tag):Connect(function(plugin)
		self:runPlugin(plugin)
	end)
	for _, plugin in pairs(CollectionService:GetTagged(Const.Tag)) do
		self:runPlugin(plugin)
	end
end

function HotSwap:StopMonitoring()
	if self.monitorConn then
		self.monitorConn:Disconnect()
		self.monitorConn = nil
	end
end

return HotSwap
