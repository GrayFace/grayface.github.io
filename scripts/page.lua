local include = require"utils".include

local P = {
	new = debug.getinfo(1, "f").func,
	NeedTOC = false,
}

function P.Include(fname, t)
	t = t or P.new()
	t.PageId = t.PageId or path.setext(fname, '')
	return include(fname, t), t
end

function P.SetTitle(short, long)
	P.Title = long or short
	P.MenuTitle = short
end

function P.TOC()
	P.NeedTOC = true
end

function P.GetPath(s, base)
	-- print(s, base)
	s = ("^"..s):match("(.-)%^*$")
	base = ("^"..(base or "")):match("(.-)%^*$")
	while true do
		local s1, s2 = s:match"%^([^%^]*)(.*)"
		local b1, b2 = base:match"%^([^%^]*)(.*)"
		if not s1 or b1 ~= s1 then
			break
		end
		s, base = s2, b2
	end
	local ret = (base:gsub("[^%^]*%^[^%^]*", "/..")..s:gsub("%^", "/")):gsub("^/", "")
	-- print(s, base, ret)
	return ret
end

function P.CloseTag(s)
	local t = P.ResTable
	t[#t+1] = "</"..s..">"
end

local function conv(s)
	if type(s) ~= "string" then
		return s
	end
	return tonumber(s:gsub("#", ""):gsub('0x', ""), 16)
end

function P.MixCl(a, b, p)
	a = conv(a)
	b = conv(b)
	p = p or 0.5
	local function mix(mask)
		return (math.min(mask, (a:And(mask)*p + b:And(mask)*(1-p)):round())):And(mask)
	end
	return ("%x"):format(mix(0xFF) + mix(0xFF0000) + mix(0xFF00))
end

function P.RGB(r, g, b)
	if b then
		return ("%x%x%x"):format(r, g, b)
	else
		r = conv(r)
	end
	return ("%s, %s, %s"):format(r:And(0xFF0000)/0x10000, r:And(0xFF00)/0x100, r:And(0xFF))
end

function P.Escape(s, cont)
	s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	if not cont or cont == '"' then
		s = s:gsub('"', "&quot;")
	end
	if not cont or cont == "'" then
		s = s:gsub("'", "&#39;")
	end
	-- this doesn't cover all contexts: https://wonko.com/post/html-escaping
	return s
end

return P