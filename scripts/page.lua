local include = require"utils".include

local P = {
	new = debug.getinfo(1, "f").func,
	NeedTOC = false,
}

function P.Include(fname, t)
	t = t or P.new()
	local id = path.setext(fname, '')
	t.PageId = t.PageId or id == "index" and "" or id
	return include(fname == ".htm" and "index.htm" or fname, t), t
end

function P.SetTitle(short, long)
	P.Title = long or short
	P.MenuTitle = short
end

function P.TOC()
	P.NeedTOC = true
end

local function DoGetPath(s, base)
	s = ("/"..s):gsub("%^", "/"):match("(.-)/*$")
	base = ("/"..base):gsub("%^", "/"):match("(.-)/*$")
	while true do
		local s1, s2 = s:match"%^([^/]*)(.*)"
		local b1, b2 = base:match"%^([^/]*)(.*)"
		if not s1 or b1 ~= s1 then
			break
		end
		s, base = s2, b2
	end
	local ret = (base:gsub("[^/]*/[^/]*", "/..")..s):gsub("^/", "")
	return ret
end

function P.GetPath(s, base)
	base = base or P.PageId
	if s:match("img[/%^]") then
		return "en|"..DoGetPath(s, base).."|ru|"..DoGetPath(s, 'ru^'..base).."|"
	end
	return DoGetPath(s, base)
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

-- this doesn't cover all contexts: https://wonko.com/post/html-escaping
function P.Escape(s, cont)
	s = s:gsub("&", "&amp;")
	if not cont or cont == 'main' then
		s = s:gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\r?\n", "<br>")
	end
	if not cont or cont == '"' then
		s = s:gsub('"', "&quot;")
	end
	if not cont or cont == "'" then
		s = s:gsub("'", "&#39;")
	end	
	return s
end

-- incomplete on purpose, so that ecs(esc(s)) = esc(s) if it's an URL with %20 etc.
function P.EscapeURL(s, cont)
	return P.Escape(s, cont):gsub('[%z- ]', |s| ('%%%x'):format(s:byte()))
end

local function LinkData(name)
	return require'dataLinks'[name]
end

local function ToLink(lnk)
	if not lnk:match("^https?://") then
		return P.GetPath(lnk)
	end
	return P.EscapeURL(lnk, '"')
end

function P.GetLink(name)
	return ToLink(LinkData(name)[1])
end

function P.LinkVer(name)
	return "v"..LinkData(name).Version
end

local MirrorLink = [[<a href="%s" title="en|Download from|ru|Скачать с| GitHubru|'а|">%s</a><a href="%s" class="mirror" title="ru|Зеркало на |SourceForgeen| Mirror|"><img src="https://sourceforge.net/favicon.ico" alt="(en|Mirror|ru|Зеркало|)"></a>]]

function P.CustomLink(lnk, title, mirrorSF)
	lnk = ToLink(lnk)
	title = P.Escape(title, 'main')
	local q = P.ResTable
	if mirrorSF then
		q[#q+1] = MirrorLink:format(lnk, title, ToLink(mirrorSF))
	else
		q[#q+1] = ('<a href="%s" title="en|Download|ru|Скачать|">%s</a>'):format(lnk, title)
	end
end

function P.Link(name, title)
	local t = LinkData(name)
	title = title or t.Name
	if title:match("##") then
		title = title:gsub("##", P.LinkVer(name))
	end
	title = title..(t.NameSuffix or "")
	P.CustomLink(t[1], title, t.MirrorSF)
end

function P.HeaderLink(name, title, tag)
	tag = tag or 'h3'
	local q = P.ResTable
	q[#q+1] = '<'..tag..'>'
	P.Link(name, title)
	q[#q+1] = '</'..tag..'>'
end

-- SourceForge mirror:
-- <style>
-- 	.mirror, .mirror:hover, .mirror:link:hover {
-- 		background-color:transparent;
-- 	}
-- 	.mirror {
-- 		margin-left: 0.2em;
-- 		margin-right: 0.2em;
-- 	}
-- 	h3 .mirror {
-- 		margin-left: 0.3em;
-- 	}
-- 	.mirror img {
-- 		vertical-align:middle;
-- 		height:1em;
-- 		margin: -0.1em 0 0.1em;
-- 		border-radius:4px;
-- 	}
-- 	h3 .mirror img {
-- 		margin: -0.1em -7px 0.1em 0;
-- 	}
-- 	.mirror img:hover {
-- 	 	background-color: #E8E8FF;
-- 	}
-- </style>
-- <h3><a href="https://sites.google.com/site/sergroj/mm/MMArchive.rar?attredirects=0" title="en|Download from|ru|Скачать с| GitHubru|'а|">MMArchive v1.2</a><a href="https://sourceforge.net/favicon.ico" class="mirror" title="ru|Зеркало на |SourceForgeen| Mirror|"><img src="https://sourceforge.net/favicon.ico" alt="en|Mirror|ru|Зеркало|" title="ru|Зеркало на |SourceForgeen| Mirror|" style=""></a></h3>
-- Fully-featured M&amp;M and Heroes 3 archives editor. <a href="https://sites.google.com/site/sergroj/mm/MMArchive.rar?attredirects=0" title="en|Download from|ru|Скачать с| GitHubru|'а|">MMArchive v1.2</a><a href="https://sourceforge.net/favicon.ico" class="mirror" title="ru|Зеркало на |SourceForgeen| Mirror|"><img src="https://sourceforge.net/favicon.ico" alt="en|Mirror|ru|Зеркало|" style=""></a> supports all archive types except ".hwl".

-- Alternative style (not ok)
-- <style>h3 img {
-- 	position: absolute;
-- 	left: 12px;
-- 	top: -2px;
-- 	height: 1em;
-- 	min-width: 1em;
-- 	padding: 3px;
-- 	border-radius: 50%;
-- 	border: 1px solid rgba(0,0,0,0.35);
-- 	box-shadow: 1px 1px 0 0 rgba(0,0,0,0.4);
-- 	/* margin-left: -4px; */
-- }
-- h3 img:hover {
-- 	background-color: #E8E8FF;
-- }	
-- </style>
-- <a name="MMArchive"></a><h3><a href="https://sites.google.com/site/sergroj/mm/MMArchive.rar?attredirects=0" title="en|Download from|ru|Скачать с| GitHubru|'а|">MMArchive v1.2</a><a href="https://sourceforge.net/favicon.ico" style="position:relative"><img src="https://sourceforge.net/favicon.ico" alt="Mirror" title="ru|Зеркало на |SourceForgeen| Mirror|"></a></h3>


return P