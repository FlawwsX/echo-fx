local Charset = {}

for i = 48,  57 do table.insert(Charset, string.char(i)) end
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

function GetRandomString(length)
	math.randomseed(GetGameTimer())

	if length > 0 then
		return GetRandomString(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end

function Round(value, numDecimalPlaces)
	return MathRound(value, numDecimalPlaces)
end

function commaValue(amount)
	local formatted = amount
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then break end
	end
	return formatted
end

exports("GetRandomString", GetRandomString)
exports("Round", Round)
exports("commaValue",commaValue)