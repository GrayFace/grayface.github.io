local utils = require"utils"
local page = require"page"
local dir = path.dir(path.noslash(path.dir(debug.FunctionFile(1))))
os.chdir(dir)

local q, q2, names = {}, {}, {}

local function ExtractLinks(fname)
	-- local all = {}
	s = io.load(fname)
	s = s:gsub('<a [^>]-href="([^"]*)"[^>]*>([^<]*)</a>', |s, name| do
		s = s:gsub("%%20", " "):gsub("&amp;", "&")
		-- all[s] = true
		local s1 = s:match("[^?]*"):match(".*/([^/]+)/?$")
		if not s1 or path.ext(s1) == "" then
			if s:match("/sergroj/") then
				print(s)
			end
			return
		elseif path.ext(s1) == ".rar" then
			s1 = path.setext(s1, '')
		end
		if s:match("sites.google") then
			q[s1] = s
			assert(not q2[s1])
		elseif s:match("dropbox") then
			q2[s1] = s
			assert(not q[s1])
		else
			return
		end
		-- assert(not names[s1] or names[s1] == name)
		if not names[s1] or names[s1] == name then
		else
		-- if path.ext(s1):lower() == ".png" then
			print(s1, names[s1], name)
		end
		names[s1] = name
		return ("-[Link(%q, %q)]"):format(s1, name:gsub(" v%d+[%d%.]*", " ##"))
		-- print(name)
	end)
	s = s:gsub('<br>[ \t\r\n]*(</h%d>)', '%1')
	s = s:gsub('<(h%d)>[ \t\r\n]*%-%[Link%((.-)%)%][ \t\r\n]*</h%d>', |h, s|
		return (h == 'h3' and '-[HeaderLink(%s)]' or '-[HeaderLink(%s, "%s")]'):format(s, h)
	)
	io.save('c/'..fname, s)
	-- s:gsub('()<a [^>]-href="([^"]*)"()', |n1, s1, n2| do
	-- 	-- local s1 = s1:match("[^?]*"):match(".*/([^/]+)/?$")
	-- 	-- if s1 and path.ext(s1):lower() == ".png" then
	-- 	-- 	print(s1, names[s1])
	-- 	-- end
	-- 	if not all[s1] then
	-- 		print(s:sub(n1, n2))--s)
	-- 	end
	-- end)
end

for fname in path.find("*.htm") do
	fname = path.name(fname)
	ExtractLinks(fname)
	local s, t = page.Include(fname)
	t.Content = s
	-- local _ = {utils.enru(s)}
	-- for _, s in ipairs(_) do
	-- 	local all = {}
	-- 	s:gsub('<a [^>]-href="([^"]*)"[^>]*>([^<]*)</a>', |s, name| do
	-- 		all[s] = true
	-- 		local s1 = s:match("[^?]*"):match(".*/([^/]+)/?$")
	-- 		if not s1 or path.ext(s1) == "" then
	-- 			return
	-- 		elseif path.ext(s1) == ".rar" then
	-- 			s1 = path.setext(s1, '')
	-- 		end
	-- 		if s:match("sites.google") then
	-- 			q[s1] = s
	-- 			assert(not q2[s1])
	-- 		elseif s:match("dropbox") then
	-- 			q2[s1] = s
	-- 			assert(not q[s1])
	-- 		else
	-- 			return
	-- 		end
	-- 		-- assert(not names[s1] or names[s1] == name)
	-- 		-- if not names[s1] or names[s1] == name then
	-- 		-- else
	-- 		-- if path.ext(s1):lower() == ".png" then
	-- 		-- 	print(s1, names[s1], name)
	-- 		-- end
	-- 		names[s1] = name
	-- 		-- print(name)
	-- 	end)
	-- 	s:gsub('()<a [^>]-href="([^"]*)"()', |n1, s1, n2| do
	-- 		local s1 = s1:match("[^?]*"):match(".*/([^/]+)/?$")
	-- 		if s1 and path.ext(s1):lower() == ".png" then
	-- 			print(s1, names[s1])
	-- 		end
	-- 		-- if not all[s1] then
	-- 		-- 	print(s:sub(n1, n2))--s)
	-- 		-- end
	-- 	end)
	-- 	-- assert(n == 0)
	-- end
	s = page.Include("templates/main.htm", t)
	s = s:gsub(" %- ([^%d])", " &ndash; %1")
	local en, ru = utils.enru(s)
	fname = t.GetPath(t.PageId).."/index.html"
	io.save(ReadyPath..fname, en)
	io.save(ReadyPath.."ru/"..fname, ru)
end

local function dataLinks(q)
	local t = {}
	for k, v in pairs(q) do
		t[k] = {
			v,
			OriginalVersion = names[k]:match(" v(%d+[%d%.]*)"),
		}
	end
	print(dump(t))
end

dataLinks(q)
dataLinks(q2)

-- print(dump(q))

-- local s = io.load[[c:\_Delphi\MMExtHelp\Site\mech_en.htm]]
-- print(require"RSParse".gsub(s, {
-- 	main = {
-- 		{import = "check"},
-- 		ret = "</span>"
-- 	},
-- 	inside = {
-- 		{import = "check"},
-- 		ret = {"</span>", gsub = ""}
-- 	},
-- 	check = {
-- 		{"<span>", gsub = "", call = "inside"},
-- 		{"<span ", call = "main"},
-- 	},
-- }))
