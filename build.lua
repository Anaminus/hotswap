local targetPath = (...) or "HotSwap.rbxm"
print("Building", targetPath)

local plugin = DataModel.new()

local function addDirectory(dir, target)
	for _, f in ipairs(fs.dir(dir)) do
		if not f.IsDir then
			local script = fs.read(os.join(dir, f.Name), "modulescript.lua")
			script.Parent = target
		end
	end
end

fs.read("src/Main.lua", "script.lua").Parent = plugin
fs.read("src/HotSwap.lua").Parent = plugin
fs.read("src/Const.lua").Parent = plugin
local assets = fs.read("src/Assets.lua")
assets.Parent = plugin
fs.read("assets/data.lua").Parent = assets
local lion = fs.read("src/Lion.lua")
lion.Parent = plugin
fs.read("src/Path.lua").Parent = plugin
fs.read("src/Tooltip.lua").Parent = plugin
fs.read("src/Widget.lua").Parent = plugin

addDirectory("l10n", lion)

fs.write(targetPath, plugin, "rbxm")
