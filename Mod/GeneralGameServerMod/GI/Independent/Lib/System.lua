--[[
Title: System
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local System = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/System.lua");
------------------------------------------------------------
]]

local System = module("System");

function GetFullPath(path, directory)
	directory = directory or __module__.__directory__ or "";
	if (string.match(path, "^[^/\\@%%]")) then path = directory .. "/" .. path end
	path = ToCanonicalFilePath(path, "linux");
	local paths = split(path, "/");
	local filenames = {};
	for _, filename in ipairs(paths) do
		if (filename == ".") then
		elseif (filename == "..") then
			table.remove(filenames, #filenames);
		else
			table.insert(filenames, #filenames + 1, filename);
		end
	end
	local full_path = table.concat(filenames, "/");
	return ToCanonicalFilePath(full_path);
end

local __checkyield_key__ = nil;
local __checkyield_count__ = 0;
local __checkyield_tick_count__ = 0;
function __checkyield__()
	local cur_tick_count = __get_tick_count__();
	if (__checkyield_tick_count__ == cur_tick_count) then
		__checkyield_count__ = __checkyield_count__ + 1;
	else
		__checkyield_tick_count__ = cur_tick_count;
		__checkyield_count__ = 0;
	end

	-- 同一时刻循环1000次 则让出协程
	if (__checkyield_count__ > 1000) then sleep() end
end

function __fileline__(filename, line_no, line_text)
	__current_filename__, __current_line_no__, __current_line_text__ = filename, line_no, line_text;
	if (__is_debug__) then
		print("__fileline__", __current_filename__, __current_line_no__, __current_line_text__);
	end
end
