
--[[
Title: Simulator
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local Simulator = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/Simulator.lua");
-------------------------------------------------------
]]

local Simulator = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});

function Simulator.Generate(window)
    return EventSimulator.DefaultGenerate(window);
end

function Simulator.Trigger(params, window)
    return EventSimulator.DefaultTrigger(params, window);
end

function Simulator.Handler(params, window)
    return EventSimulator.DefaultHandler(params, window);
end