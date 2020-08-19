local targetPath = (...) or "HotSwap.rbxm"
print("Building", targetPath)

local plugin = DataModel.new()

local function addDirectory(dir, target)
	local folder = Instance.new("Folder")
	folder.Name = target
	folder.Parent = plugin
	for _, f in ipairs(os.dir(dir)) do
		local script = file.read(os.join(dir, f.Name), "modulescript.lua")
		script.Parent = folder
	end
end

file.read("src/Main.lua", "script.lua").Parent = plugin
file.read("src/HotSwap.lua").Parent = plugin
file.read("src/Const.lua").Parent = plugin
local assets = file.read("src/Assets.lua")
assets.Parent = plugin
file.read("assets/data.lua").Parent = assets
file.read("src/Lion.lua").Parent = plugin
file.read("src/Path.lua").Parent = plugin
file.read("src/Tooltip.lua").Parent = plugin
file.read("src/Widget.lua").Parent = plugin

addDirectory("l10n", "Lion")

file.write(targetPath, plugin, "rbxm")
