local plugin = script.Parent
local HotSwap = require(plugin.HotSwap)

local Path = {
	objects = {},
}

local function disconnect(connections)
	for i = 1, #connections do
		connections[i]:Disconnect()
		connections[i] = nil
	end
end

local function update(entry)
	disconnect(entry.nameConns)
	local prev = entry.name
	if HotSwap:IsUnsafe(entry.object) then
		entry.name = "<unsafe>"
		if entry.name ~= prev then
			entry.callback(entry.name)
		end
		return
	end
	entry.name = entry.object:GetFullName()
	if entry.name ~= prev then
		entry.callback(entry.name)
	end
	local parent = entry.object.Parent
	while parent do
		if HotSwap:IsUnsafe(parent) then
			break
		end
		table.insert(entry.nameConns, parent:GetPropertyChangedSignal("Name"):Connect(function()
			update(entry)
		end))
		parent = parent.Parent
	end
end

function Path:Add(object, cb)
	if HotSwap:IsUnsafe(object) then
		return
	end
	local entry; entry = {
		object = object,
		callback = cb,
		name = nil,
		nameConns = {},
		nameConn = object:GetPropertyChangedSignal("Name"):Connect(function()
			update(entry)
		end),
		ancestryConn = object.AncestryChanged:Connect(function()
			update(entry)
		end),
	}
	update(entry)
	self.objects[object] = entry
end

function Path:Remove(object)
	local entry = self.objects[object]
	if entry == nil then
		return
	end
	self.objects[object] = nil
	entry.nameConn:Disconnect()
	entry.nameConn = nil
	entry.ancestryConn:Disconnect()
	entry.ancestryConn = nil
	disconnect(entry.nameConns)
end

return Path
