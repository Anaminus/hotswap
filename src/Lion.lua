local locale = game:GetService("LocalizationService").SystemLocaleId
local keys = script:FindFirstChild(locale)
if keys == nil then
	locale = "en-us"
	keys = script[locale]
end
local entries = {}
for key, value in pairs(require(keys)) do
	table.insert(entries, {
		Key = key,
		Values = {[locale] = value},
	})
end

local Lion = {
	table = Instance.new("LocalizationTable"),
	translator = nil
}
Lion.table:SetEntries(entries)
Lion.translator = Lion.table:GetTranslator(locale)

return setmetatable(Lion, {
	__index = function(self, key)
		return function(...)
			return self.translator:FormatByKey(key, ...)
		end
	end,
})
