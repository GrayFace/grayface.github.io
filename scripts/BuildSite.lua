package.loaded.dataLinks = nil
require"misc"
local utils = require"utils"
local page = require"page"
local dir = path.dir(path.noslash(path.dir(debug.FunctionFile(1))))
os.chdir(dir)

for fname in path.find("*.htm") do
	fname = path.name(fname)
	local s, t = page.Include(fname)
	if not t.CancelGeneration then
		t.Content = s
		s = page.Include("templates/main.htm", t)
		local en, ru = utils.enru(s)
		fname = t.GetPath(t.PageId, "").."/index.html"
		io.save(ReadyPath..fname, en)
		io.save(ReadyPath.."ru/"..fname, ru)
	end
end

for fname in path.find("*.txt") do
	local s = io.load(fname)
	fname = path.name(fname)
	local t = page.new()
	local name = path.name(t.GetPath(path.setext(fname, ''), ""))
	t.PageId = path.setext(fname, ''):gsub(' ', '')
	if not t.CancelGeneration then
		t.Content = page.Escape(s)
		t.SetTitle(name, name..path.ext(fname))
		s = page.Include("templates/main.htm", t)
		s = s:gsub(" %- ([^%d])", " &ndash; %1")
		local en, ru = utils.enru(s)
		fname = t.GetPath(t.PageId, "").."/index.html"
		io.save(ReadyPath..fname, en)
		io.save(ReadyPath.."ru/"..fname, ru)
	end
end

for fname in path.find("*.xml") do
	fname = path.name(fname)
	local s, t = page.Include(fname)
	local en, ru = utils.enru(s)
	io.save(ReadyPath..fname, en)
	io.save(ReadyPath.."ru/"..fname, ru)
end
