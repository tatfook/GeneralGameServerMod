--[[
Title: TickEvent
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local TickEvent = NPL.load("Mod/GeneralGameServerMod/GI/Game/Input/TickEvent.lua");
------------------------------------------------------------
]]

local Event = NPL.load("./Event.lua");
local TickEvent = commonlib.inherit(Event, NPL.export());


function TickEvent:ctor()
end

function TickEvent:Init()
    self:SetEventType("TickEvent");

    return self; 
end
