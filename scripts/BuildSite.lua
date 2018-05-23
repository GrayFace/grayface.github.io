local utils = require"utils"
local page = require"page"
local dir = path.dir(path.noslash(path.dir(debug.FunctionFile(1))))
os.chdir(dir)

for fname in path.find("*.htm") do
	fname = path.name(fname)
	local s, t = page.Include(fname)
	t.Content = s
	s = page.Include("templates/main.htm", t)
	s = s:gsub(" %- ([^%d])", " &ndash; %1")
	local en, ru = utils.enru(s)
	fname = t.GetPath(t.PageId, "").."/index.html"
	io.save(ReadyPath..fname, en)
	io.save(ReadyPath.."ru/"..fname, ru)
end
