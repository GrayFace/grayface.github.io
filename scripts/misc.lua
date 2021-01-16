local function conv(s)
	if type(s) ~= "string" then
		return s
	end
	return tonumber(s:gsub('#', ""):gsub('0x', ""), 16)
end

function MixCl(a, b, p)
	a = conv(a)
	b = conv(b)
	p = p or 0.5
	local function mix(mask)
		return (math.min(mask, (a:And(mask)*p + b:And(mask)*(1-p)):round())):And(mask)
	end
	return ("%x"):format(mix(0xFF) + mix(0xFF0000) + mix(0xFF00))
end

function RGB(r, g, b)
	if b then
		return ("%x%x%x"):format(r, g, b)
	elseif type(r) == "string" then
		r = tonumber(r:gsub('#', ""):gsub('0x', ""), 16)
	end
	return ("%s, %s, %s"):format(r:And(0xFF0000)/0x10000, r:And(0xFF00)/0x100, r:And(0xFF))
end
