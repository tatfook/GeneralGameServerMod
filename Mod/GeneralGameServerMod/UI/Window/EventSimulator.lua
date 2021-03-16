--[[
Title: EventSimulator
Author(s): wxa
Date: 2020/6/30
Desc: EventSimulator
use the lib:
-------------------------------------------------------
local EventSimulator = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/EventSimulator.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
NPL.load("(gl)script/ide/System/Windows/KeyEvent.lua");
local KeyEvent = commonlib.gettable("System.Windows.KeyEvent");
local InputMethodEvent = commonlib.gettable("System.Windows.InputMethodEvent");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local EventSimulator = NPL.export();

local simulators = {};         -- 模拟器
local simulator_params = {};   -- 事件参数

local function GetButtonsState()
    local buttons_state = 0;
    if(ParaUI.IsMousePressed(0)) then buttons_state = buttons_state + 1 end
    if(ParaUI.IsMousePressed(1)) then buttons_state = buttons_state + 2 end
    return buttons_state;
end

function Macros.UIWindowEvent(params)
    local window = EventSimulator.GetWindow(params.macro_name);
    if (not window) then return end
    return window:EventSimulatorHandler(params);
end

function Macros.UIWindowEventTrigger(params)
    local window = EventSimulator.GetWindow(params.macro_name);
    if (not window) then return end
    return window:EventSimulatorTrigger(params);
end

function EventSimulator.SetClickTrigger(mouseX, mouseY, mouseButton)
    local callback = {};
    MacroPlayer.SetClickTrigger(mouseX, mouseY, mouseButton, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

function EventSimulator.SetDragTrigger(startX, startY, endX, endY, mouseButton)
    local callback = {};
    MacroPlayer.SetDragTrigger(startX, startY, endX, endY, mouseButton, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

function EventSimulator.SetKeyPressTrigger(buttons, targetText)
    local callback = {};
    MacroPlayer.SetKeyPressTrigger(buttons, targetText, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

function EventSimulator.IsRecording()
    return Macros:IsRecording()
end

function EventSimulator.IsPlaying()
    return Macros:IsPlaying()
end

function EventSimulator.AddMacro(params)
    Macros:AddMacro("UIWindowEvent", params);                   -- 为方便扩展, 参数尽量使用对象
end

function EventSimulator.GetSimulatorParams()
    return simulator_params;
end

function EventSimulator.GetEventParams()
    if (not simulator_params.event_params) then simulator_params.event_params = {} end
    return simulator_params.event_params;
end

function EventSimulator.DefaultHandler(params, window)
    local macro_type = params.macro_type;
    if (params.macro_type == "UIWindowClick") then
        return EventSimulator.UIWindowClick(params, window);
    elseif (macro_type == "UIWindowKeyBoard") then
        return EventSimulator.UIWindowKeyBoard(params, window);
    end
end

function EventSimulator.DefaultTrigger(params, window)
    local macro_type = params.macro_type;
    if (macro_type == "UIWindowClick") then
        return EventSimulator.UIWindowClickTrigger(params, window);
    elseif (macro_type == "UIWindowKeyBoard") then
        return EventSimulator.UIWindowKeyBoardTrigger(params, window);
    end
end

function EventSimulator.InitSimulatorParams(window)
    local event_type = window:GetEventType();

    simulator_params.macro_type = nil;
    simulator_params.last_event_type = simulator_params.event_type;
    simulator_params.event_type = event_type;

    if (event_type == "ondraw") then return end

    if (event_type == "onmousedown") then 
        simulator_params.down_mouse_x, simulator_params.down_mouse_y = ParaUI.GetMousePosition(); 
        simulator_params.down_mouse_win_x, simulator_params.down_mouse_win_y = window:ScreenPointToWindowPoint(simulator_params.down_mouse_x, simulator_params.down_mouse_y);   -- 窗口坐标为虚拟的绝对坐标, 不启用窗口自动缩放, 该不会变化
        simulator_params.down_window_x, simulator_params.down_window_y = window:GetScreenPosition();
        -- 鼠标按键信息以按下为准
        simulator_params.mouse_buttons_state = GetButtonsState();  
        simulator_params.mouse_button = mouse_button;
    end
    
    if (event_type == "onmouseup") then 
        simulator_params.up_mouse_x, simulator_params.up_mouse_y = ParaUI.GetMousePosition();
        simulator_params.up_mouse_win_x, simulator_params.up_mouse_win_y = window:ScreenPointToWindowPoint(simulator_params.up_mouse_x, simulator_params.up_mouse_y);
        simulator_params.up_window_x, simulator_params.up_window_y = window:GetScreenPosition();
        simulator_params.window_offset_x, simulator_params.window_offset_y = simulator_params.up_window_x - simulator_params.down_window_x, simulator_params.up_window_y - simulator_params.down_window_y;
        simulator_params.mouse_down_up_distance = math.max(math.abs(simulator_params.up_mouse_x - simulator_params.down_mouse_x), math.abs(simulator_params.up_mouse_y - simulator_params.down_mouse_y));         -- 距离为屏幕距离
    end

    if (event_type == "onkeydown") then
        local event = KeyEvent:init("keyPressEvent");
        simulator_params.ctrl_pressed, simulator_params.shift_pressed, simulator_params.alt_pressed, simulator_params.keyname, simulator_params.key_sequence = event.ctrl_pressed, event.shift_pressed, event.alt_pressed, event.keyname, event.key_sequence;
    end

    if (event_type == "oninputmethod") then
        simulator_params.commit_string = msg;
    end
end

function EventSimulator.DefaultGenerate(window)
    local macro_name = window:GetMacroName();
    local event_type = window:GetEventType();
    if (not macro_name) then return end

    -- 提取参数
    EventSimulator.InitSimulatorParams(window);

    if (event_type == "ondraw") then return end
    if (event_type == "onmousedown") then return end
   
    -- 添加宏
    if (event_type == "onmouseup") then 
        EventSimulator.AddMacro({
            macro_type = "UIWindowClick",
            macro_name = macro_name,
            simulator_name = simulator_params.simulator_name,
            event_params = simulator_params.event_params,
            mouse_button = simulator_params.mouse_button, 
            buttons_state = simulator_params.mouse_buttons_state, 
            mouse_down_x = simulator_params.down_mouse_win_x, 
            mouse_down_y = simulator_params.down_mouse_win_y, 
            mouse_up_x = simulator_params.up_mouse_win_x, 
            mouse_up_y = simulator_params.up_mouse_win_y, 
            window_offset_x = simulator_params.window_offset_x, 
            window_offset_y = simulator_params.window_offset_y, 
            mouse_down_up_distance = simulator_params.mouse_down_up_distance,
        });
    end

    if (event_type == "onkeydown") then
        local is_input_method = simulator_params.last_event_type == "oninputmethod"; -- oninputmethod => onkeydown
        EventSimulator.AddMacro({
            macro_type = "UIWindowKeyBoard", 
            macro_name = macro_name, 
            simulator_name = simulator_params.simulator_name,
            event_params = simulator_params.event_params,
            ctrl_pressed = simulator_params.ctrl_pressed,
            shift_pressed = simulator_params.shift_pressed,
            alt_pressed = simulator_params.alt_pressed,
            keyname = simulator_params.keyname,
            key_sequence = simulator_params.key_sequence,
            is_input_method = is_input_method,
            commit_string = is_input_method and simulator_params.commit_string or nil,
        });
    end
end

function EventSimulator.Register(simulator_name, simulator)
    simulators[simulator_name] = simulator;
end

function EventSimulator.Generate(simulator_name, window)
    local simulator = simulator_name and simulators[simulator_name] or EventSimulator.Simulator;
    -- 设置模拟器
    simulator_params.simulator_name = simulator_name;
    -- 模拟事件
    simulator.Generate(window);
    -- 清除事件参数
    simulator_params.simulator_name = nil;
    simulator_params.event_params = nil;
end

function EventSimulator.Trigger(params, window)
    local simulator = params.simulator_name and simulators[params.simulator_name] or EventSimulator.Simulator;
    return simulator.Trigger(params, window);
end

function EventSimulator.Handler(params, window)
    local simulator = params.simulator_name and simulators[params.simulator_name] or EventSimulator.Simulator;
    return simulator.Handler(params, window);
end


local windows = {};
if (IsDevEnv) then
    _G.windows = _G.windows or {};
    windows = _G.windows;
end

function EventSimulator.SetWindow(name, window)
    if (not name) then return end
    windows[name] = window;
end

function EventSimulator.GetWindow(name)
    if (not name) then return end
    return windows[name];
end

function EventSimulator.UIWindowClick(params, window)
    local mouse_down_x, mouse_down_y = window:WindowPointToScreenPoint(params.mouse_down_x, params.mouse_down_y);
    local mouse_up_x, mouse_up_y = window:WindowPointToScreenPoint(params.mouse_up_x, params.mouse_up_y);
    local mouse_button, buttons_state = params.mouse_button, params.buttons_state;
    mouse_up_x, mouse_up_y = mouse_up_x + params.window_offset_x, mouse_up_y + params.window_offset_y;
    window:OnEvent("onmousedown", {mouse_x = mouse_down_x, mouse_y = mouse_down_y, mouse_button = mouse_button, buttons_state = buttons_state});
    if (params.mouse_down_up_distance > 4) then 
        window:OnEvent("onmousemove", {mouse_x = mouse_down_x + (mouse_up_x > mouse_down_x and 4 or -4), mouse_y = mouse_down_y, mouse_button = mouse_button, buttons_state = buttons_state});
        window:OnEvent("onmousemove", {mouse_x = mouse_up_x, mouse_y = mouse_up_y, mouse_button = mouse_button, buttons_state = buttons_state});
    end
    window:OnEvent("onmouseup", {mouse_x = mouse_up_x, mouse_y = mouse_up_y, mouse_button = mouse_button, buttons_state = buttons_state});
end

function EventSimulator.UIWindowClickTrigger(params, window)
    if (params.mouse_down_up_distance > 4) then 
        -- 拖拽
        local startX, startY = window:WindowPointToScreenPoint(params.mouse_down_x, params.mouse_down_y);
        local endX, endY = window:WindowPointToScreenPoint(params.mouse_up_x, params.mouse_up_y);
        endX, endY = endX + params.window_offset_x, endY + params.window_offset_y;
        return EventSimulator.SetDragTrigger(startX, startY, endX, endY, params.mouse_button);
    else
        -- 点击
        local x, y = window:WindowPointToScreenPoint(params.mouse_down_x, params.mouse_down_y);
        return EventSimulator.SetClickTrigger(x, y, params.mouse_button);
    end
end

function EventSimulator.UIWindowKeyBoard(params, window)
    if (params.is_input_method) then window:HandleKeyEvent(InputMethodEvent:new():init(params.commit_string)) end    
    local event = KeyEvent:init("keyPressEvent");
    event.keyname, event.shift_pressed, event.alt_pressed, event.ctrl_pressed, event.key_sequence = params.keyname, params.shift_pressed, params.alt_pressed, params.ctrl_pressed, params.key_sequence;
    window:HandleKeyEvent(event);
end

function EventSimulator.UIWindowKeyBoardTrigger(params, window)
    local buttons, macro_type = params.keyname or "", params.macro_type or "";
	if(params.ctrl_pressed) then buttons = "ctrl+"..buttons end
	if(params.alt_pressed) then buttons = "alt+"..buttons end
	if(params.shift_pressed) then buttons = "shift+"..buttons end
    if (buttons == "") then return end

    -- get final text in editbox
    local nOffset = 0;
    local targetText = "";
    while(true) do
        nOffset = nOffset + 1;
        local nextMacro = Macros:PeekNextMacro(nOffset)
        if (not nextMacro or (nextMacro.name ~= "Idle" and nextMacro.name ~= "UIWindowEvent" and nextMacro.name ~= "UIWindowEventTrigger")) then break end
        if(nextMacro.name == "UIWindowEvent" and macro_type == "UIWindowKeyBoard") then
            local params = nextMacro:GetParams()[1];
            if(not params.commit_string or not params.keyname or not Macros.IsButtonLetter(params.keyname)) then break end
            targetText = targetText .. params.commit_string;
        end
    end
    if(targetText and targetText ~= "") then
        local nOffset = 0;
        while(true) do
            nOffset = nOffset - 1;
            local nextMacro = Macros:PeekNextMacro(nOffset)
            if (not nextMacro or (nextMacro.name ~= "Idle" and nextMacro.name ~= "UIWindowEvent" and nextMacro.name ~= "UIWindowEventTrigger")) then break end
            if(nextMacro.name == "UIWindowEvent" and macro_type == "UIWindowKeyBoard") then
                local params = nextMacro:GetParams()[1];
                if(not params.commit_string or not params.keyname or not Macros.IsButtonLetter(params.keyname)) then break end
                targetText = params.commit_string .. targetText;
            end
        end
    end

    return EventSimulator.SetKeyPressTrigger(buttons, targetText);
end

local Simulator = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});

function Simulator.Generate(window)
    return EventSimulator.DefaultGenerate(window);
end

function Simulator.Trigger(params, window)
    window:SetSimulatorEventParams(params.event_params);
    return EventSimulator.DefaultTrigger(params, window);
end

function Simulator.Handler(params, window)
    window:SetSimulatorEventParams(params.event_params);
    return EventSimulator.DefaultHandler(params, window);
end

EventSimulator.Simulator = Simulator;