
local function disconnect(self, field)
	if self[field] then
		self[field]:Disconnect()
		self[field] = nil
	end
end

local Tooltip = {
	frames = {},
	func = nil,
	inside = 0,
}

function Tooltip:Callback(func)
	self.func = func
end

function Tooltip:update(state, frame)
	self.inside = self.inside + state
	if not self.func then
		return
	end
	if state > 0 then
		local data = self.frames[frame]
		if data then
			self.func(data.message)
		end
	elseif state < 0 and self.inside == 0 then
		self.func("")
	end
end

function Tooltip:Set(frame, message)
	local data = self.frames[frame]
	if data and message == nil then
		self.frames[frame] = nil
		disconnect(data, "enterConn")
		disconnect(data, "leaveConn")
		return
	end
	if data then
		data.message = message
		return
	end
	data = {
		frame = frame,
		message = message,
		enterConn = nil,
		leaveConn = nil,
	}
	data.enterConn = frame.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		self:update(1, frame)
	end)
	data.leaveConn = frame.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		self:update(-1, frame)
	end)
	self.frames[frame] = data
end

return Tooltip
