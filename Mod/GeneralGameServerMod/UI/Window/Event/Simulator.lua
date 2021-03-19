
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

NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local Params = NPL.load("./Params.lua", IsDevEnv);
local Simulator = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Simulator:Property("SimulatorName", "Simulator");               -- 模拟器名称

local windows = {};
if (IsDevEnv) then
    _G.windows = _G.windows or {};
    windows = _G.windows;
end
local window_id = 0;
local simulators = {};
local default_simulator_name = "DefaultSimulatorName";

function Macros.UIWindowEvent(params)
    local window = windows[params.window_name];
    local simulator = simulators[params.simulator_name];
    if (not window or not simulator) then return end
    return simulator:Handler(params, window);
end

function Macros.UIWindowEventTrigger(params)
    local window = windows[params.window_name];
    local simulator = simulators[params.simulator_name];
    if (not window or not simulator) then return end
    return simulator:Trigger(params, window);
end

function Simulator:AddVirtualEvent(virtualEventType, virtualEventParams)
    if (not self:IsRecording()) then return end 
    
    Macros:AddMacro("UIWindowEvent", {
        window_name = Params:GetWindowName(),
        event_type = Params:GetEventType(),
        simulator_name = self:GetSimulatorName(),
        virtual_event_type = virtualEventType,
        virtual_event_params = virtualEventParams,
    });                 
end

function Simulator:IsRecording()
    return Macros:IsRecording()
end

function Simulator:IsPlaying()
    return Macros:IsPlaying()
end

function Simulator:SetClickTrigger(mouseX, mouseY, mouseButton)
    local callback = {};
    MacroPlayer.SetClickTrigger(mouseX, mouseY, mouseButton, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

function Simulator:SetDragTrigger(startX, startY, endX, endY, mouseButton)
    local callback = {};
    MacroPlayer.SetDragTrigger(startX, startY, endX, endY, mouseButton, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

function Simulator:SetKeyPressTrigger(buttons, targetText)
    local callback = {};
    MacroPlayer.SetKeyPressTrigger(buttons, targetText, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

function Simulator:SetDefaultSimulatorName(simulator_name)
    default_simulator_name = simulator_name;
end

function Simulator:GetDefaultSimulatorName()
    return default_simulator_name;
end

function Simulator:GetDefaultSimulator()
    return default_simulator_name and simulators[default_simulator_name] or Simulator;
end

function Simulator:ctor()
    self:RegisterSimulator();
end

function Simulator:Init(event, window)
    Params:Init(event, window);
    return self;
end

function Simulator:Finish(event, window)
end

function Simulator:Trigger(params, window)
    return self:TriggerVirtualEvent(params.virtual_event_type, params.virtual_event_params, window);
end

function Simulator:TriggerVirtualEvent(virtualEventType, virtualEventParams, window)
end

function Simulator:Handler(params, window)
    return self:HandlerVirtualEvent(params.virtual_event_type, params.virtual_event_params, window);
end

function Simulator:HandlerVirtualEvent(virtualEventType, virtualEventParams, window)
end

function Simulator:RegisterSimulator()
    simulators[self:GetSimulatorName()] = self;
end

function Simulator:RegisterWindow(window)
    local windowName = window:GetWindowName();
    if (not windowName or windowName == "") then return end
    windows[windowName] = window;
end

function Simulator:UnregisterWindow(window)
    local windowName = window:GetWindowName();
    if (not windowName or windowName == "") then return end
    windows[windowName] = nil;
end

Simulator:InitSingleton();

Simulator.DefaultSimulator = NPL.load("./DefaultSimulator.lua", IsDevEnv);


local function MacroBeginRecord()
    window_id  = 0;
end
local function MacroEndRecord()
end
local function MacroBeginPlay()
    window_id  = 0;
end
local function MacroEndPlay()
end
GameLogic.GetFilters():add_filter("Macro_BeginRecord", MacroBeginRecord);
GameLogic.GetFilters():add_filter("Macro_EndRecord", MacroEndRecord);
GameLogic.GetFilters():add_filter("Macro_BeginPlay", MacroBeginPlay);
GameLogic.GetFilters():add_filter("Macro_EndPlay", MacroEndPlay);