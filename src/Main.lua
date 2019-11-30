local HotSwap = require(plugin.HotSwap)
local Assets = require(plugin.Assets)
local Widget = require(plugin.Widget)

Assets:Preload()
Widget:Init()
if HotSwap:Enabled() and HotSwap:Active() then
	wait()
	HotSwap:StartMonitoring()
end
