local assets = require(script.data)

local keyFields = {"id", "size", "theme"}
local valueField = "content"

local Assets = setmetatable({}, {
	__index = function(self, id)
		return function(...)
			return self:Content(id, ...)
		end
	end,
})

function Assets:Preload()
	local ContentProvider = game:GetService("ContentProvider")
	local list = {}
	for _, content in pairs(assets) do
		if type(content) == "table" then
			for _, content in pairs(content) do
				if type(content) == "string" then
					table.insert(list, content)
				end
			end
		elseif type(content) == "string" then
			table.insert(list, content)
		end
	end
	coroutine.wrap(function()
		ContentProvider:PreloadAsync(list)
	end)
end

function Assets:Content(...)
	for _, asset in pairs(assets) do
		local okay = true
		for i, field in pairs(keyFields) do
			if asset[field] ~= select(i, ...) then
				okay = false
				break
			end
		end
		if okay then
			return asset[valueField]
		end
	end
	return nil
end

return Assets
