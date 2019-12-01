local plugin = script.Parent
local HotSwap = require(plugin.HotSwap)
local Const = require(plugin.Const)
local Assets = require(plugin.Assets)
local Lion = require(plugin.Lion)
local Path = require(plugin.Path)
local Tooltip = require(plugin.Tooltip)

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

local helpPanel = plugin:CreateDockWidgetPluginGui(
	Const.ID.HelpPanel,
	DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float, -- initDockState
		false,                       -- initEnabled
		true,                        -- overrideEnabledRestore
		600,                         -- floatXSize
		600,                         -- floatYSize
		400,                         -- minWidth
		300                          -- minHeight
	)
)
helpPanel.Name = Const.ID.HelpPanel
helpPanel.Title = Lion.HelpPanel_Title()

local elements = {}
function elements:Remove(body)
	for i,v in pairs(self) do
		if v.body == body then
			table.remove(self, i)
			return
		end
	end
end

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
			elseif element.type == "textbutton" then
				element.body.BackgroundColor3 = theme:GetColor(Color.Button, Mod.Default)
				element.body.Text.TextColor3 = theme:GetColor(Color.MainText, Mod.Default)
			elseif element.type == "scroll" then
				element.body.BackgroundColor3 = theme:GetColor(Color.ScrollBarBackground, Mod.Default)
				element.body.ScrollBarImageColor3 = theme:GetColor(Color.ScrollBar, Mod.Default)
			elseif element.type == "field" then
				element.body.BorderColor3 = theme:GetColor(Color.InputFieldBorder, Mod.Default)
				if element.status == "pending" then
					element.body.BackgroundColor3 = theme:GetColor(Color.DiffTextNoChangeBackground, Mod.Default)
					element.body.Text.TextColor3 = theme:GetColor(Color.DiffTextNoChange, Mod.Default)
				elseif element.status == "failed" then
					element.body.BackgroundColor3 = theme:GetColor(Color.DiffTextDeletionBackground, Mod.Default)
					element.body.Text.TextColor3 = theme:GetColor(Color.DiffTextDeletion, Mod.Default)
				elseif element.status == "running" then
					element.body.BackgroundColor3 = theme:GetColor(Color.DiffTextAdditionBackground, Mod.Default)
					element.body.Text.TextColor3 = theme:GetColor(Color.DiffTextAddition, Mod.Default)
				else
					element.body.BackgroundColor3 = theme:GetColor(Color.InputFieldBackground, Mod.Default)
					element.body.Text.TextColor3 = theme:GetColor(Color.DimmedText, Mod.Default)
				end
			elseif element.type == "label" then
				element.body.TextColor3 = theme:GetColor(Color.MainText, Mod.Default)
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
end

local buttons = {}
local pluginList
local listItemContainer
local listItemTmpl
local messageLabel
do
	local SIZE = Const.GUI.Compact.Size
	local SPACE = Const.GUI.Compact.Spacing
	local PAD = Const.GUI.Compact.Padding
	local TEXTSIZE = Const.GUI.Compact.TextSize
	local SCROLL = Const.GUI.ScrollWidth

	local buttonTmpl = Instance.new("ImageButton")
	buttonTmpl.BorderSizePixel = 0
	buttonTmpl.Size = UDim2.new(0,SIZE,0,SIZE)
	local buttonIcon = Instance.new("ImageLabel", buttonTmpl)
	buttonIcon.Name = "Icon"
	buttonIcon.BackgroundTransparency = 1
	buttonIcon.BorderSizePixel = 0
	buttonIcon.Position = UDim2.new(0,PAD,0,PAD)
	buttonIcon.Size = UDim2.new(1,-PAD*2,1,-PAD*2)

	listItemTmpl = Instance.new("Frame")
	listItemTmpl.Name = "ListItem"
	listItemTmpl.BackgroundTransparency = 1
	listItemTmpl.BorderSizePixel = 0
	listItemTmpl.Size = UDim2.new(1,-SPACE,0,SIZE)
	local listItemLabel = Instance.new("Frame", listItemTmpl)
	listItemLabel.Name = "Label"
	listItemLabel.BorderMode = Enum.BorderMode.Inset
	listItemLabel.Position = UDim2.new(0,0,0,0)
	listItemLabel.Size = UDim2.new(1,-SIZE-SPACE,1,0)
	local listItemText = Instance.new("TextLabel", listItemLabel)
	listItemText.Name = "Text"
	listItemText.BackgroundTransparency = 1
	listItemText.BorderSizePixel = 0
	listItemText.Font = Enum.Font.SourceSans
	listItemText.TextSize = TEXTSIZE
	listItemText.TextXAlignment = Enum.TextXAlignment.Left
	listItemText.TextTruncate = Enum.TextTruncate.AtEnd
	listItemText.Position = UDim2.new(0,PAD,0,0)
	listItemText.Size = UDim2.new(1,-PAD*2,1,0)
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
	pluginList.Position = UDim2.new(0,SPACE,0,SIZE+SPACE*3)
	pluginList.Size = UDim2.new(1,-SPACE*2,1,-SIZE*2-SPACE*6)
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
	listLayout.Padding = UDim.new(0,SPACE)

	buttons.enable = buttonTmpl:Clone()
	buttons.enable.Name = "EnableButton"
	buttons.enable.Position = UDim2.new(0,SPACE,0,SPACE)
	buttons.enable.Icon.Image = Assets.Enabled(32)
	if HotSwap:Active() then
		buttons.enable.Icon.ImageTransparency = 0.8
		buttons.enable.AutoButtonColor = false
	end
	buttons.enable.Parent = rootContainer
	Tooltip:Set(buttons.enable, Lion.Button_ToggleEnabled_Tooltip())
	table.insert(elements, {type="button",body=buttons.enable})

	-- buttons.changelog = buttonTmpl:Clone()
	-- buttons.changelog.Name = "ChangelogButton"
	-- buttons.changelog.Position = UDim2.new(1,-SIZE*2-SPACE*2,0,SPACE)
	-- buttons.changelog.Icon.Image = Assets.Changelog(32, "Light")
	-- buttons.changelog.Parent = rootContainer
	-- Tooltip:Set(buttons.changelog, Lion.Button_Changelog_Tooltip())
	-- table.insert(elements, {type="button",body=buttons.changelog,icon={
	-- 	Light = Assets.Changelog(32, "Light"),
	-- 	Dark = Assets.Changelog(32, "Dark"),
	-- }})

	buttons.help = buttonTmpl:Clone()
	buttons.help.Name = "HelpButton"
	buttons.help.Position = UDim2.new(1,-SIZE-SPACE,0,SPACE)
	buttons.help.Icon.Image = Assets.Help(32)
	buttons.help.Parent = rootContainer
	Tooltip:Set(buttons.help, Lion.Button_Help_Tooltip())
	table.insert(elements, {type="button",body=buttons.help})

	buttons.add = buttonTmpl:Clone()
	buttons.add.Name = "AddButton"
	buttons.add.Position = UDim2.new(0,SPACE,1,-SIZE-SPACE)
	buttons.add.Icon.Image = Assets.Add(32)
	if HotSwap:Active() then
		buttons.add.Icon.ImageTransparency = 0.8
		buttons.add.AutoButtonColor = false
	end
	buttons.add.Parent = rootContainer
	Tooltip:Set(buttons.add, Lion.Button_Add_Tooltip())
	table.insert(elements, {type="button",body=buttons.add})

	buttons.removeAll = buttonTmpl:Clone()
	buttons.removeAll.Name = "RemoveAllButton"
	buttons.removeAll.Position = UDim2.new(1,-SIZE-SPACE-SCROLL,1,-SIZE-SPACE)
	buttons.removeAll.Icon.Image = Assets.RemoveAll(32, "Light")
	if HotSwap:Active() then
		buttons.removeAll.Icon.ImageTransparency = 0.8
		buttons.removeAll.AutoButtonColor = false
	end
	buttons.removeAll.Parent = rootContainer
	Tooltip:Set(buttons.removeAll, Lion.Button_RemoveAll_Tooltip())
	table.insert(elements, {type="button",body=buttons.removeAll,icon={
		Light = Assets.RemoveAll(32, "Light"),
		Dark = Assets.RemoveAll(32, "Dark"),
	}})

	messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.BackgroundTransparency = 1
	messageLabel.BorderSizePixel = 0
	messageLabel.Text = ""
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.TextSize = TEXTSIZE
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Center
	messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
	messageLabel.Position = UDim2.new(0,SIZE+SPACE*2+PAD,1,-SIZE-SPACE)
	messageLabel.Size = UDim2.new(1,-SIZE*2-SPACE*4-PAD*2-SCROLL,0,SIZE)
	messageLabel.Parent = rootContainer
	table.insert(elements, {type="label",body=messageLabel})
end

local helpCloseButton
local helpScroll
do
	local SIZE = Const.GUI.Normal.Size
	local SPACE = Const.GUI.Normal.Spacing
	local PAD = Const.GUI.Normal.Padding
	local TEXTSIZE = Const.GUI.Normal.TextSize
	local SCROLL = Const.GUI.ScrollWidth

	local buttonTextTmpl = Instance.new("ImageButton")
	buttonTextTmpl.BorderSizePixel = 0
	buttonTextTmpl.Size = UDim2.new(0,SIZE,0,SIZE)
	local buttonText = Instance.new("TextLabel", buttonTextTmpl)
	buttonText.Name = "Text"
	buttonText.BackgroundTransparency = 1
	buttonText.BorderSizePixel = 0
	buttonText.Text = "Button"
	buttonText.Font = Enum.Font.SourceSans
	buttonText.TextSize = TEXTSIZE
	buttonText.Position = UDim2.new(0,PAD,0,PAD)
	buttonText.Size = UDim2.new(1,-PAD*2,1,-PAD*2)

	local helpContainer = Instance.new("Frame", helpPanel)
	helpContainer.Name = "HelpContainer"
	helpContainer.BorderSizePixel = 0
	helpContainer.Position = UDim2.new(0,0,0,0)
	helpContainer.Size = UDim2.new(1,0,1,0)
	table.insert(elements, {type="background",body=helpContainer})

	helpScroll = Instance.new("ScrollingFrame", helpContainer)
	helpScroll.Name = "helpScroll"
	helpScroll.BorderSizePixel = 0
	helpScroll.Position = UDim2.new(0,SIZE,0,SIZE)
	helpScroll.Size = UDim2.new(1,-SIZE*2,1,-SIZE*3-SPACE)
	helpScroll.CanvasSize = UDim2.new(0,0,0,0)
	helpScroll.ScrollBarThickness = SCROLL
	helpScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
	helpScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	helpScroll.TopImage = Assets.ScrollTop(32)
	helpScroll.MidImage = Assets.ScrollMiddle(32)
	helpScroll.BottomImage = Assets.ScrollBottom(32)
	table.insert(elements, {type="scroll",body=helpScroll})

	local background = Instance.new("Frame", helpScroll)
	background.Name = "Background"
	background.BorderSizePixel = 0
	background.Position = UDim2.new(0,0,0,0)
	background.Size = UDim2.new(1,0,1,0)
	table.insert(elements, {type="background",body=background})

	local helpLabel = Instance.new("TextLabel", helpScroll)
	helpLabel.Name = "Content"
	helpLabel.BackgroundTransparency = 1
	helpLabel.BorderSizePixel = 0
	helpLabel.Font = Enum.Font.SourceSans
	helpLabel.TextSize = TEXTSIZE
	helpLabel.TextWrapped = true
	helpLabel.TextXAlignment = Enum.TextXAlignment.Left
	helpLabel.TextYAlignment = Enum.TextYAlignment.Top
	helpLabel.Position = UDim2.new(0,PAD,0,PAD)
	helpLabel.Size = UDim2.new(1,-PAD*2,1,-PAD*2)
	table.insert(elements, {type="label",body=helpLabel})

	helpCloseButton = buttonTextTmpl:Clone()
	helpCloseButton.Name = "CloseButton"
	helpCloseButton.Text.Text = "Close"
	helpCloseButton.Position = UDim2.new(1,-SIZE*4-SIZE,1,-SIZE*2)
	helpCloseButton.Size = UDim2.new(0,SIZE*4,0,SIZE)
	helpCloseButton.Parent = helpContainer
	table.insert(elements, {type="textbutton",body=helpCloseButton})

	local helpText = Lion.HelpPanel_Content()
	helpLabel.Text = helpText:gsub("([^\n])\n([^\n])","%1 %2"):gsub("^%s*",""):gsub("%s*$","")
	local TextService = game:GetService("TextService")
	local function updateSize()
		local size = TextService:GetTextSize(
			helpLabel.Text,
			helpLabel.TextSize,
			helpLabel.Font,
			Vector2.new(helpLabel.AbsoluteSize.X, math.huge)
		)
		helpScroll.CanvasSize = UDim2.new(0,0,0,size.Y+PAD*2)
		helpLabel.Size = UDim2.new(1,-PAD*2,0,size.Y+PAD*2)
	end
	helpPanel:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize)
	updateSize()
end

local Widget = {}

function Widget:Init()
	local Selection = game:GetService("Selection")
	local Studio = settings().Studio

	Tooltip:Callback(function(message)
		messageLabel.Text = message
	end)

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

	-- buttons.changelog.MouseButton1Click:Connect(function()
	-- 	print("TODO:CHANGELOG")
	-- end)
	buttons.help.MouseButton1Click:Connect(function()
		helpScroll.CanvasPosition = Vector2.new()
		helpPanel.Enabled = not helpPanel.Enabled
	end)
	helpCloseButton.MouseButton1Click:Connect(function()
		helpPanel.Enabled = false
		helpScroll.CanvasPosition = Vector2.new()
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

	local SIZE = Const.GUI.Compact.Size
	local SPACE = Const.GUI.Compact.Spacing
	local items = {}
	local count = 0
	HotSwap.PluginAdded:Connect(function(plugin)
		if items[plugin] ~= nil then
			return
		end

		local item = listItemTmpl:Clone()
		local itemData = {
			body = item,
			label = {type="field",body=item.Label},
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
				Tooltip:Set(itemData.label.body, Lion.Label_Status_Pending_Tooltip())
			else
				Tooltip:Set(itemData.label.body, Lion.Label_Status_Disabled_Tooltip())
			end
		else
			item.RemoveButton.MouseButton1Click:Connect(function()
				HotSwap:RemovePlugin(plugin)
			end)
		end
		item.Parent = listItemContainer
		Tooltip:Set(item.RemoveButton, Lion.Button_Remove_Tooltip())
		table.insert(elements, itemData.label)
		table.insert(elements, {type="button",body=item.RemoveButton})
		UpdateTheme(Studio.Theme)

		count = count + 1
		pluginList.CanvasSize = UDim2.new(0,0,0,(SIZE+SPACE)*count-SPACE)
	end)
	HotSwap.PluginRemoved:Connect(function(plugin)
		local itemData = items[plugin]
		if itemData == nil then
			return
		end
		items[plugin] = nil
		Path:Remove(plugin)
		Tooltip:Set(itemData.body.Label)
		Tooltip:Set(itemData.body.RemoveButton)
		elements:Remove(itemData.body.Label)
		elements:Remove(itemData.body.RemoveButton)
		itemData.body:Destroy()
		count = count - 1
		pluginList.CanvasSize = UDim2.new(0,0,0,(SIZE+SPACE)*count-SPACE)
	end)
	if HotSwap:Active() and HotSwap:Enabled() then
		local running = 0
		panel.Title = Lion.Panel_Title_Status({running})
		HotSwap.PluginStatus:Connect(function(plugin, okay, message)
			local itemData = items[plugin]
			if itemData == nil then
				return
			end
			if okay then
				itemData.label.status = "running"
				Tooltip:Set(itemData.label.body, Lion.Label_Status_Running_Tooltip())
				running = running + 1
				panel.Title = Lion.Panel_Title_Status({running})
			else
				itemData.label.status = "failed"
				Tooltip:Set(itemData.label.body, Lion.Label_Status_Failed_Tooltip({message}))
			end
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
