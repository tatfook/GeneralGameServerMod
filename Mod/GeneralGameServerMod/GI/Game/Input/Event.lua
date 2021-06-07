--[[
Title: Event
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Event = NPL.load("Mod/GeneralGameServerMod/GI/Game/Input/Event.lua");
------------------------------------------------------------
]]

local Event = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Event:Property("EventType"); -- 事件类型

function Event:ctor()
end

function Event:Init()
    return self; 
end
