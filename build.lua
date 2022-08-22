local targetPath, assetPath = ...

targetPath = targetPath or "HotSwap.rbxm"
local ext = path.split(targetPath, "fext")
if ext ~= ".rbxm" and ext ~= ".rbxmx" then
	print(string.format("incompatable extension %q", ext))
	return
end
print("Building", targetPath)

-- Add each module in dir as a child to target.
local function addModules(dir, target)
	for _, f in ipairs(fs.dir(dir)) do
		if not f.IsDir and path.split(f.Name, "fext") == ".lua" then
			local script = fs.read(path.join(dir, f.Name))
			script.Parent = target
		end
	end
end

-- Create plugin root.
local plugin = Instance.new("DataModel")

-- Include main script with version number.
local main = fs.read("src/Main.lua", "script.lua")
main.Parent = plugin

fs.read("src/HotSwap.lua").Parent = plugin
fs.read("src/Const.lua").Parent = plugin
fs.read("src/Path.lua").Parent = plugin
fs.read("src/Tooltip.lua").Parent = plugin
fs.read("src/Widget.lua").Parent = plugin

-- Include asset data.
local assets = fs.read("src/Assets.lua")
assets.Parent = plugin
if assetPath then
	local data = fs.read("assets/data_dev.lua")
	data.Name = "data"
	data.Parent = assets
else
	fs.read("assets/data.lua").Parent = assets
end

-- Include localization data.
local lion = fs.read("src/Lion.lua")
lion.Parent = plugin
addModules("l10n", lion)

-- Copy icon to asset directory.
if assetPath then
	local dir = path.join(assetPath, "hotswap")
	fs.mkdir(dir)

	local icon32 = fs.read("assets/icon/icon_32.png", "bin")
	fs.write(path.join(dir, "icon_32.png"), icon32, "bin")
end

fs.write(targetPath, plugin, "rbxm")
