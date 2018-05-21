local P = {}

local RSParse = require"RSParse"
local tpl = require"RSTemplates".new()
local r = tpl.rules
r.main = {
	{import = "check"},
	"<!%-%-.-%-%->",
	{"<style>", call = "style"},
	{"<style ", call = {"attribs", "style"}},
	{"<script>", call = "script"},
	{"<script ", call = {"attribs", "script"}},
}
r.style = {
	{import = "check"},
	{"%$(%w+)", gsub = "(%1)", call = "quick"},
	ret = "</style>",
	"/%*.-%*/",
}
r.quick = {
	ret = {"!?", gsub = ""},
}
r.script = {
	{import = "check"},
	ret = "</script>",
	"/%*.-%*/",
	"//[^\r\n]*",
	{"'", call = "str1"},
	{'"', call = "str2"},
}
r.attribs = {
	{import = "check"},
	ret = ">",
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
	return RSParse.gsub(s, {
		{"en|([^|]*)|", gsub = ru and "" or "%1"},
		{"ru|([^|]*)|", gsub = ru and "%1" or ""},
	})
end

function P.enru(s)
	return Conv(s), Conv(s, true)
end

return P