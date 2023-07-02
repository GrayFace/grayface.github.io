local P = {}

local RSParse = require"RSParse"
local tpl = require"RSTemplates".new()
local r = tpl.rules
r.main = {
	{import = "checkmain"},
	{"<style>", call = "style"},
	{"<style ", call = {"attribs", "style"}},
	{"<script>", call = "script"},
	{"<script ", call = {"attribs", "script"}},
	{"<[^/ $>]+", call = "attribs"},
	{"<%$%[", call = {"qmain", "attribs"}, gsub = "(Escape("},
}
r.checkmain = {
	{import = "check"},
	"<!%-%-.-%-%->",
	{"%$%[", call = "qmain", gsub = "(Escape(("},
}
r.style = {
	{import = "check"},
	{"%$(%w+)", gsub = "(%1)", call = "qstyle"},
	{"%$%[", gsub = "(", call = "qgen"},
	ret = "</style>",
	"/%*.-%*/",
}
r.qstyle = {
	ret = {"", gsub = ""},
}
r.qgen = {
	{"%]", ret = true, gsub = ")"},
	{import = "code"},
}
r.qmain = {
	{"%]", ret = true, gsub = "), 'main'))"},
	{import = "code"},
}
r.qattrib1 = {
	{"%]", ret = true, gsub = "), \"'\"))"},
	{import = "code"},	
}
r.qattrib2 = {
	{"%]", ret = true, gsub = "), '\"'))"},
	{import = "code"},	
}
r.qattribVal = {
	{"%]", ret = true, gsub = "), '\"')..'\"')"},
	{import = "code"},	
}
r.script = {
	{import = "check"},
	{"%$%[", gsub = "(", call = "qgen"},
	ret = "</script>",
	"/%*.-%*/",
	"//[^\r\n]*",
	{"'", call = "str1"},
	{'"', call = "str2"},
}
r.attribs = {
	{import = "checkmain"},
	{import = "attribStr"},
	{"=", call = "attribVal"},
	ret = ">",
}
r.attribStr = {
	{"'", call = "attrib1"},
	{'"', call = "attrib2"},
}
r.attrib1 = {
	{"%$%[", call = "qattrib1", gsub = "(Escape(("},
	{import = "check"},
	{import = "str1"},
}
r.attrib2 = {
	{"%$%[", call = "qattrib2", gsub = "(Escape(("},
	{import = "check"},
	{import = "str2"},
}
r.attribVal = {
	{"()>", capture2 = 1, ret = true},
	{"%$%[", call = "qattribVal", gsub = "('\"'..Escape(("},
	{import = "attribStr", ret = true},
	{import = "checkmain"},
	ret = " ",
}

function P.include(fname, ...)
	local q = tpl.prepare(io.load(fname))
	local code = q.code0.." "..q.code
	local s, err = tpl.run(q, ...)
	return s or error(err.."\n\n"..code)
end

local function Conv(s, ru)
	s = RSParse.gsub(s, {
		main = {
			{"`en|", gsub = ru and "\1" or "", call = (ru and "close1" or "close")},
			{"`ru|", gsub = ru and "" or "\1", call = (ru and "close" or "close1")},
			{"`%-", gsub = "&ndash;"}
			-- {" %- `en|", gsub = ru and " &ndash; \1" or " &ndash; ", call = (ru and "close1" or "close")},
			-- {" %- `ru|", gsub = ru and " &ndash; " or " &ndash; \1", call = (ru and "close" or "close1")},
			-- {" %- ([^%d])", gsub = " &ndash; %1"}
			-- {"|", gsub = error},
		},
		close1 = {
			{import = "main"},
			ret = {"`?|", gsub = "\2"},
		},
		close = {
			{import = "main"},
			ret = {"`?|", gsub = ""},
		},
	})
	return s:gsub("%b\1\2", "")
end

function P.enru(s)
	return Conv(s), Conv(s, true)
end

-- local DashRules
-- do
-- 	local r = {
-- 		str1 = {"\\.", ret = "'"},
-- 		str2 = {"\\.", ret = '"'},
-- 	}
-- 	r.main = {
-- 		{import = "checkmain"},
-- 		{"<style>", call = "style"},
-- 		{"<style ", call = {"attribs", "style"}},
-- 		{"<script>", call = "script"},
-- 		{"<script ", call = {"attribs", "script"}},
-- 		{"<[^/ $>]+", call = "attribs"},
-- 		{" %- ()[^%d]", gsub = " &ndash; ", capture2 = 1}
-- 	}
-- 	r.checkmain = {
-- 		"<!%-%-.-%-%->",
-- 	}
-- 	r.style = {
-- 		ret = "</style>",
-- 		"/%*.-%*/",
-- 	}
-- 	r.script = {
-- 		ret = "</script>",
-- 		"/%*.-%*/",
-- 		"//[^\r\n]*",
-- 		{"'", call = "str1"},
-- 		{'"', call = "str2"},
-- 	}
-- 	r.attribs = {
-- 		{import = "checkmain"},
-- 		{import = "attribStr"},
-- 		{"=", call = "attribVal"},
-- 		ret = ">",
-- 	}
-- 	r.attribStr = {
-- 		{"'", call = "attrib1"},
-- 		{'"', call = "attrib2"},
-- 	}
-- 	r.attrib1 = {
-- 		{import = "str1"},
-- 	}
-- 	r.attrib2 = {
-- 		{import = "str2"},
-- 	}
-- 	r.attribVal = {
-- 		{"()>", capture2 = 1, ret = true},
-- 		{import = "attribStr", ret = true},
-- 		{import = "checkmain"},
-- 		ret = " ",
-- 	}
-- 	DashRules = r
-- end

-- local function gsplit(str, rules, n, i)
-- 	n = n and n*2 or 1/0
-- 	if n <= 0 then
-- 		return {str}
-- 	end
-- 	local t, j, n0, cur = {}, 1, 1, nil
-- 	local last = 1
-- 	RSParse.parse(str, rules, function(n1, n2, q, k0, mode, stack, i)
-- 		print(mode, str:sub(last, n2))
-- 		last = n2 + 1
-- 		cur = cur or n1 >= n0 and q.gsub
-- 		if cur and not q.import then
-- 			t[j] = string.sub(str, n0, n1 - 1)
-- 			local s1 = q.gpattern or type(q[1]) == "string" and q[1] or ".*"
-- 			t[j+1] = string.gsub(string.sub(str, n1, n2), s1, cur, q.gcount or 1)
-- 			n0, j, cur = n2 + 1, j + 2, nil
-- 			if j > n then
-- 				return true
-- 			end
-- 		end
-- 	end, i)
-- 	t[j] = string.sub(str, n0)
-- 	return t
-- end

-- -- Patterns in 'rules' table can have an extra 'gsub' field for replacement strings.
-- -- 'n' is the total number of replacements, like in 'string.gsub'.
-- -- 'i' is the index from which the search starts.
-- function mygsub(str, rules, n, i)
-- 	return table.concat(gsplit(str, rules, n, i))
-- end


-- function P.ConvDash(s)
-- 	print'---------------------------------'
-- 	return mygsub(s, DashRules) --RSParse.gsub(s, DashRules)
-- end

return P