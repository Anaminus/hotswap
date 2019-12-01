local targetPath = (...) or "HotSwap.rbxm"
print("Building", targetPath)
local targetInput = rbxmk.input{"generate://Instance"}

local function addDirectory(dir, target)
	for _, file in pairs(rbxmk.readdir{dir}) do
		rbxmk.map{
			rbxmk.output{targetInput,target},
			rbxmk.input{format="modulescript.lua",
				rbxmk.path{dir, file.name},
			},
		}
	end
end

rbxmk.map{rbxmk.output{targetInput},rbxmk.input{format="script.lua","src/Main.lua"}}
rbxmk.map{rbxmk.output{targetInput},rbxmk.input{format="modulescript.lua","src/HotSwap.lua"}}
rbxmk.map{rbxmk.output{targetInput},rbxmk.input{format="modulescript.lua","src/Const.lua"}}
rbxmk.map{rbxmk.output{targetInput},rbxmk.input{format="modulescript.lua","src/Assets.lua"}}
rbxmk.map{rbxmk.output{targetInput},rbxmk.input{format="modulescript.lua","src/Lion.lua"}}
rbxmk.map{rbxmk.output{targetInput},rbxmk.input{format="modulescript.lua","src/Path.lua"}}
rbxmk.map{rbxmk.output{targetInput},rbxmk.input{format="modulescript.lua","src/Tooltip.lua"}}
rbxmk.map{rbxmk.output{targetInput},rbxmk.input{format="modulescript.lua","src/Widget.lua"}}

rbxmk.map{rbxmk.output{targetInput,"Assets"},rbxmk.input{format="modulescript.lua","assets/data.lua"}}

addDirectory("l10n", "Lion")

rbxmk.delete{rbxmk.output{targetPath}}
rbxmk.map{targetInput, rbxmk.output{targetPath}}
