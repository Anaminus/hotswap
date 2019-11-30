local plugin = script.Parent
local HotSwap = require(plugin.HotSwap)
local Const = require(plugin.Const)
local Assets = require(plugin.Assets)
local Lion = require(plugin.Lion)
local Path = require(plugin.Path)

local toolbar = plugin:CreateToolbar("HotSwap")
local toolbarButton = toolbar:CreateButton(
	Const.ID.ToolbarTogglePanel,
	Lion.Toolbar_TogglePanel_Tooltip(),
	Assets.Logo(32),
	Lion.Toolbar_TogglePanel_Text()
)

local actions = {
	TogglePanel = plugin:CreatePluginAction(
		Const.ID.ActionTogglePanel,
		Lion.Action_TogglePanel_Text(),
		Lion.Action_TogglePanel_StatusTip(),
		Assets.Logo(16),
		true
	),
	ToggleEnabled = plugin:CreatePluginAction(
		Const.ID.ActionToggleEnabled,
		Lion.Action_ToggleEnabled_Text(),
		Lion.Action_ToggleEnabled_StatusTip(),
		Assets.Enabled(16),
		true
	),
	Add = plugin:CreatePluginAction(
		Const.ID.ActionAdd,
		Lion.Action_Add_Text(),
		Lion.Action_Add_StatusTip(),
		Assets.Add(16),
		true
	),
	Remove = plugin:CreatePluginAction(
		Const.ID.ActionRemove,
		Lion.Action_Remove_Text(),
		Lion.Action_Remove_StatusTip(),
		Assets.Remove(16),
		true
	),
	RemoveAll = plugin:CreatePluginAction(
		Const.ID.ActionRemoveAll,
		Lion.Action_RemoveAll_Text(),
		Lion.Action_RemoveAll_StatusTip(),
		Assets.RemoveAll(16, "Light"),
		true
	),
}

local panel = plugin:CreateDockWidgetPluginGui(
	Const.ID.Panel,
	DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Right, -- initDockState
		false,                       -- initEnabled
		false,                       -- overrideEnabledRestore
		400,                         -- floatXSize
		200,                         -- floatYSize
		200,                         -- minWidth
		150                          -- minHeight
	)
)
panel.Name = Const.ID.Panel
panel.Title = Lion.Panel_Title()

local elements = {}
function elements:Remove(body)
	for i,v in pairs(self) do
		if v.body == body then
			table.remove(self, i)
			return
		end
	end
end


local buttons = {}
local pluginList
local listItemContainer
local listItemTmpl
local UpdateTheme
do
	local Color = Enum.StudioStyleGuideColor
	local Mod = Enum.StudioStyleGuideModifier
	local function updateElement(theme, element)
		if type(element) == "table" then
			if element.type == "background" then
				element.body.BackgroundColor3 = theme:GetColor(Color.MainBackground, Mod.Default)
			elseif element.type == "button" then
				element.body.BackgroundColor3 = theme:GetColor(Color.Button, Mod.Default)
				element.body.Icon.ImageColor3 = theme:GetColor(Color.MainText, Mod.Default)
				if element.icon then
					local icon = element.icon[theme.Name]
					if icon then
						element.body.Icon.Image = icon
					end
				end
			elseif element.type == "scroll" then
				element.body.BackgroundColor3 = theme:GetColor(Color.ScrollBarBackground, Mod.Default)
				element.body.ScrollBarImageColor3 = theme:GetColor(Color.ScrollBar, Mod.Default)
			elseif element.type == "label" then
				element.body.BorderColor3 = theme:GetColor(Color.InputFieldBorder, Mod.Default)
				if element.status == "pending" then
					element.body.BackgroundColor3 = theme:GetColor(Color.DiffTextNoChangeBackground, Mod.Default)
					element.body.Text.TextColor3 = theme:GetColor(Color.DiffTextNoChange, Mod.Default)
				elseif element.status == "error" then
					element.body.BackgroundColor3 = theme:GetColor(Color.DiffTextDeletionBackground, Mod.Default)
					element.body.Text.TextColor3 = theme:GetColor(Color.DiffTextDeletion, Mod.Default)
				elseif element.status == "okay" then
					element.body.BackgroundColor3 = theme:GetColor(Color.DiffTextAdditionBackground, Mod.Default)
					element.body.Text.TextColor3 = theme:GetColor(Color.DiffTextAddition, Mod.Default)
				else
					element.body.BackgroundColor3 = theme:GetColor(Color.InputFieldBackground, Mod.Default)
					element.body.Text.TextColor3 = theme:GetColor(Color.DimmedText, Mod.Default)
				end
			end
		end
	end
	function UpdateTheme(theme, element)
		if element then
			return updateElement(theme, element)
		end
		for _, element in pairs(elements) do
			updateElement(theme, element)
		end
	end

	local SIZE = Const.GUI.Size
	local PAD = Const.GUI.Padding
	local SCROLL = Const.GUI.ScrollWidth

	local buttonTmpl = Instance.new("ImageButton")
	buttonTmpl.BorderSizePixel = 0
	buttonTmpl.Size = UDim2.new(0,SIZE,0,SIZE)
	local buttonIcon = Instance.new("ImageLabel", buttonTmpl)
	buttonIcon.Name = "Icon"
	buttonIcon.BackgroundTransparency = 1
	buttonIcon.BorderSizePixel = 0
	buttonIcon.Position = UDim2.new(0,2,0,2)
	buttonIcon.Size = UDim2.new(1,-4,1,-4)

	listItemTmpl = Instance.new("Frame")
	listItemTmpl.Name = "ListItem"
	listItemTmpl.BackgroundTransparency = 1
	listItemTmpl.BorderSizePixel = 0
	listItemTmpl.Size = UDim2.new(1,-PAD,0,SIZE)
	local listItemLabel = Instance.new("Frame", listItemTmpl)
	listItemLabel.Name = "Label"
	listItemLabel.BorderMode = Enum.BorderMode.Inset
	listItemLabel.Position = UDim2.new(0,0,0,0)
	listItemLabel.Size = UDim2.new(1,-SIZE-PAD,1,0)
	local listItemText = Instance.new("TextLabel", listItemLabel)
	listItemText.Name = "Text"
	listItemText.BackgroundTransparency = 1
	listItemText.BorderSizePixel = 0
	listItemText.Font = Enum.Font.SourceSans
	listItemText.TextSize = 14
	listItemText.TextXAlignment = Enum.TextXAlignment.Left
	listItemText.TextTruncate = Enum.TextTruncate.AtEnd
	listItemText.Position = UDim2.new(0,2,0,0)
	listItemText.Size = UDim2.new(1,-4,1,0)
	local removeButton = buttonTmpl:Clone()
	removeButton.Name = "RemoveButton"
	removeButton.Position = UDim2.new(1,-SIZE,0,0)
	removeButton.Icon.Image = Assets.Remove(32)
	removeButton.Parent = listItemTmpl

	local rootContainer = Instance.new("Frame", panel)
	rootContainer.Name = "RootContainer"
	rootContainer.BorderSizePixel = 0
	rootContainer.Position = UDim2.new(0,0,0,0)
	rootContainer.Size = UDim2.new(1,0,1,0)
	table.insert(elements, {type="background",body=rootContainer})

	pluginList = Instance.new("ScrollingFrame", rootContainer)
	pluginList.Name = "PluginList"
	pluginList.BorderSizePixel = 0
	pluginList.Position = UDim2.new(0,PAD,0,SIZE+PAD*3)
	pluginList.Size = UDim2.new(1,-PAD*2,1,-SIZE*2-PAD*6)
	pluginList.CanvasSize = UDim2.new(0,0,0,0)
	pluginList.ScrollBarThickness = SCROLL
	pluginList.VerticalScrollBarInset = Enum.ScrollBarInset.Always
	pluginList.ScrollingDirection = Enum.ScrollingDirection.Y
	pluginList.TopImage = Assets.ScrollTop(32)
	pluginList.MidImage = Assets.ScrollMiddle(32)
	pluginList.BottomImage = Assets.ScrollBottom(32)
	table.insert(elements, {type="scroll",body=pluginList})
	listItemContainer = Instance.new("Frame", pluginList)
	listItemContainer.Name = "ItemContainer"
	listItemContainer.BorderSizePixel = 0
	listItemContainer.Position = UDim2.new(0,0,0,0)
	listItemContainer.Size = UDim2.new(1,0,1,0)
	table.insert(elements, {type="background",body=listItemContainer})
	local listLayout = Instance.new("UIListLayout", listItemContainer)
	listLayout.Padding = UDim.new(0,PAD)

	buttons.enable = buttonTmpl:Clone()
	buttons.enable.Name = "EnableButton"
	buttons.enable.Position = UDim2.new(0,PAD,0,PAD)
	buttons.enable.Icon.Image = Assets.Enabled(32)
	if HotSwap:Active() then
		buttons.enable.Icon.ImageTransparency = 0.8
		buttons.enable.AutoButtonColor = false
	end
	buttons.enable.Parent = rootContainer
	table.insert(elements, {type="button",body=buttons.enable})

	buttons.changelog = buttonTmpl:Clone()
	buttons.changelog.Name = "ChangelogButton"
	buttons.changelog.Position = UDim2.new(1,-SIZE*2-PAD*2,0,PAD)
	buttons.changelog.Icon.Image = Assets.Changelog(32, "Light")
	buttons.changelog.Parent = rootContainer
	table.insert(elements, {type="button",body=buttons.changelog,icon={
		Light = Assets.Changelog(32, "Light"),
		Dark = Assets.Changelog(32, "Dark"),
	}})

	buttons.help = buttonTmpl:Clone()
	buttons.help.Name = "HelpButton"
	buttons.help.Position = UDim2.new(1,-SIZE-PAD,0,PAD)
	buttons.help.Icon.Image = Assets.Help(32)
	buttons.help.Parent = rootContainer
	table.insert(elements, {type="button",body=buttons.help})

	buttons.add = buttonTmpl:Clone()
	buttons.add.Name = "AddButton"
	buttons.add.Position = UDim2.new(0,PAD,1,-SIZE-PAD)
	buttons.add.Icon.Image = Assets.Add(32)
	if HotSwap:Active() then
		buttons.add.Icon.ImageTransparency = 0.8
		buttons.add.AutoButtonColor = false
	end
	buttons.add.Parent = rootContainer
	table.insert(elements, {type="button",body=buttons.add})

	buttons.removeAll = buttonTmpl:Clone()
	buttons.removeAll.Name = "RemoveAllButton"
	buttons.removeAll.Position = UDim2.new(1,-SIZE-PAD-SCROLL,1,-SIZE-PAD)
	buttons.removeAll.Icon.Image = Assets.RemoveAll(32, "Light")
	if HotSwap:Active() then
		buttons.removeAll.Icon.ImageTransparency = 0.8
		buttons.removeAll.AutoButtonColor = false
	end
	buttons.removeAll.Parent = rootContainer
	table.insert(elements, {type="button",body=buttons.removeAll,icon={
		Light = Assets.RemoveAll(32, "Light"),
		Dark = Assets.RemoveAll(32, "Dark"),
	}})
end

local Widget = {}

function Widget:Init()
	local Selection = game:GetService("Selection")
	local Studio = settings().Studio

	local function togglePanel()
		panel.Enabled = not panel.Enabled
	end
	local function toggleEnabled()
		HotSwap:SetEnabled(not HotSwap:Enabled())
	end
	local function add()
		for _, selection in pairs(Selection:Get()) do
			HotSwap:AddPlugin(selection)
		end
	end
	local function remove()
		for _, selection in pairs(Selection:Get()) do
			HotSwap:RemovePlugin(selection)
		end
	end
	local function removeAll()
		HotSwap:RemoveAllPlugins()
	end

	toolbarButton.ClickableWhenViewportHidden = true
	toolbarButton.Click:Connect(togglePanel)

	actions.TogglePanel.Triggered:Connect(togglePanel)

	buttons.changelog.MouseButton1Click:Connect(function()
		print("TODO:CHANGELOG")
	end)
	buttons.help.MouseButton1Click:Connect(function()
		print("TODO:HELP")
	end)

	if not HotSwap:Active() then
		actions.ToggleEnabled.Triggered:Connect(toggleEnabled)
		actions.Add.Triggered:Connect(add)
		actions.Remove.Triggered:Connect(remove)
		actions.RemoveAll.Triggered:Connect(removeAll)

		buttons.enable.MouseButton1Click:Connect(toggleEnabled)
		buttons.add.MouseButton1Click:Connect(add)
		buttons.removeAll.MouseButton1Click:Connect(removeAll)
	end

	local SIZE = Const.GUI.Size
	local PAD = Const.GUI.Padding
	local items = {}
	local count = 0
	HotSwap.PluginAdded:Connect(function(plugin)
		if items[plugin] ~= nil then
			return
		end

		local item = listItemTmpl:Clone()
		local itemData = {
			body = item,
			label = {type="label",body=item.Label},
		}
		items[plugin] = itemData
		local text = item.Label.Text
		Path:Add(plugin, function(name)
			text.Text = name
		end)
		if HotSwap:Active() then
			item.RemoveButton.Icon.ImageTransparency = 0.8
			item.RemoveButton.AutoButtonColor = false
			if HotSwap:Enabled() then
				itemData.label.status = "pending"
			end
		else
			item.RemoveButton.MouseButton1Click:Connect(function()
				HotSwap:RemovePlugin(plugin)
			end)
		end
		item.Parent = listItemContainer
		table.insert(elements, itemData.label)
		table.insert(elements, {type="button",body=item.RemoveButton})
		UpdateTheme(Studio.Theme)

		count = count + 1
		pluginList.CanvasSize = UDim2.new(0,0,0,(SIZE+PAD)*count-PAD)
	end)
	HotSwap.PluginRemoved:Connect(function(plugin)
		local itemData = items[plugin]
		if itemData == nil then
			return
		end
		items[plugin] = nil
		Path:Remove(plugin)
		elements:Remove(itemData.body.Label)
		elements:Remove(itemData.body.RemoveButton)
		itemData.body:Destroy()
		count = count - 1
		pluginList.CanvasSize = UDim2.new(0,0,0,(SIZE+PAD)*count-PAD)
	end)
	if HotSwap:Active() and HotSwap:Enabled() then
		HotSwap.PluginStatus:Connect(function(plugin, okay, message)
			local itemData = items[plugin]
			if itemData == nil then
				return
			end
			itemData.label.status = okay and "okay" or "error"
			UpdateTheme(Studio.Theme, itemData.label)
		end)
	end

	local function updateVisible()
		toolbarButton:SetActive(panel.Enabled)
	end
	panel:GetPropertyChangedSignal("Enabled"):Connect(updateVisible)
	updateVisible()

	local enabledIcon = Assets.Enabled(32)
	local disabledIcon = Assets.Disabled(32)
	local function updateEnabled(enabled)
		if enabled then
			buttons.enable.Icon.Image = enabledIcon
		else
			buttons.enable.Icon.Image = disabledIcon
		end
	end
	HotSwap.EnabledChanged:Connect(updateEnabled)
	updateEnabled(HotSwap:Enabled())

	Studio.ThemeChanged:Connect(function()
		UpdateTheme(Studio.Theme)
	end)
	UpdateTheme(Studio.Theme)
end

return Widget
