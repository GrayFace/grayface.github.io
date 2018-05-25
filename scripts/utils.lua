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
tpl.code0 = tpl.code0..";(...).ResTable=({...})[2]"

function P.include(fname, t)
	t.ResTable = nil
	local q = tpl.prepare(io.load(fname))
	local code = q.code0.." "..q.code
	local s, err = tpl.run(q, t)
	return s or error(err.."\n\n"..code)
end

local function Conv(s, ru)
	s = RSParse.gsub(s, {
		main = {
			{"`en|", gsub = ru and "\1" or "", call = (ru and "close1" or "close")},
			{"`ru|", gsub = ru and "" or "\1", call = (ru and "close" or "close1")},
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

return P