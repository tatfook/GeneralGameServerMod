
--[[
Title: String
Author(s):  wxa
Date: 2020-06-12
Desc: String 
use the lib:
------------------------------------------------------------
local String = NPL.load("Mod/GeneralGameServerMod/CommonLib/String.lua");
------------------------------------------------------------
]]

local String = NPL.export();

function String.Trim(str, ch)
    ch = ch or "%s";
    str = string.gsub(str, "^" .. ch .. "*", "");
    str = string.gsub(str, ch .. "*$", "");
    return str;
end

function String.Find(str, substr)
    return string.find(str, substr, 1, true);
end

