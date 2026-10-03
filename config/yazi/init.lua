-- square borders around all three columns
require("full-border"):setup { type = ui.Border.PLAIN }
-- git status next to files (modified, new, ignored…)
require("git"):setup { order = 1500 }
-- bookmarks: persistent across sessions, notify on save
require("bookmarks"):setup {
	persist = "all",
	desc_format = "full",
	notify = { enable = true, timeout = 1, message = { new = "Bookmark '<key>' saved", delete = "Bookmark '<key>' deleted", delete_all = "All bookmarks deleted" } },
}

-- right column of the file list: size + modification date
function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		time = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time = os.date("%d %b %H:%M", time)
	else
		time = os.date("%d %b  %Y", time)
	end
	local size = self._file:size()
	return string.format("%s  %s", size and ya.readable_size(size) or "-", time)
end

-- header: user@host before the path
Header:children_add(function()
	if ya.target_family() ~= "unix" then
		return ""
	end
	return ui.Line {
		ui.Span(" 󰉋 "):fg("#6f86b6"),
		ui.Span(ya.user_name() .. "@" .. ya.host_name() .. "  "):fg("#7c8190"),
	}
end, 500, Header.LEFT)

-- status bar: owner:group of the hovered file
Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end
	return ui.Line {
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("#7c8190"),
		ui.Span(":"):fg("#4a5064"),
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("#7c8190"),
		" ",
	}
end, 500, Status.RIGHT)

-- status bar: modification date of the hovered file, before the permissions
Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or not h.cha.mtime then
		return ""
	end
	return ui.Line {
		ui.Span("󰃰 "):fg("#9aa8c6"),
		ui.Span(os.date("%d %b %H:%M", math.floor(h.cha.mtime)) .. "  "):fg("#b9b29a"),
	}
end, 400, Status.RIGHT)
