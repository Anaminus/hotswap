local assets = require(script.data)

local Assets = setmetatable({}, {
	__index = function(self, id)
		return function(size)
			return self:Content(id, size)
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

function Assets:Content(id, size)
	local content = assets[id]
	if type(content) == "table" then
		return content[size]
	elseif type(content) == "string" then
		return content
	end
	return nil
end

return Assets
