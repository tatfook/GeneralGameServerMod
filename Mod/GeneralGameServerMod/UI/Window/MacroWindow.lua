
--[[
Title: MacroWindow
Author(s): wxa
Date: 2020/6/30
Desc: MacroWindow
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/MacroWindow.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local Event = NPL.load("./Event.lua");
-- local MacroWindow = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local MacroWindow = NPL.export();

-- 鼠标位置
local mouse_down_x, mouse_down_y, mouse_down_time, mouse_up_x, mouse_up_y, mouse_up_time = 0, 0, 0, 0, 0, 0;
local mouse_down_win_x, mouse_down_win_y, mouse_up_win_x, mouse_up_win_y, win_x, win_y = 0, 0, 0, 0, 0, 0;
local mouse_buttons_state = 0;
local windows = {};

if (IsDevEnv) then
    _G.windows = _G.windows or {};
    windows = _G.windows;
end

local function SetClickTrigger(mouseX, mouseY, mouseButton)
    local callback = {};
    MacroPlayer.SetClickTrigger(mouseX, mouseY, mouseButton, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

local function SetDragTrigger(startX, startY, endX, endY, mouseButton)
    local callback = {};
    MacroPlayer.SetDragTrigger(startX, startY, endX, endY, mouseButton, function()
        if(callback.OnFinish) then
            callback.OnFinish();
        end
    end);
    return callback;
end

local function AddMacro(funcname, params)
    Macros:AddMacro(funcname, params);                   -- 为方便扩展, 参数尽量使用对象
end

local function GetButtonsState()
    local buttons_state = 0;
    if(ParaUI.IsMousePressed(0)) then buttons_state = buttons_state + 1 end
    if(ParaUI.IsMousePressed(1)) then buttons_state = buttons_state + 2 end
    return buttons_state;
end

function Macros.UIWindowClick(params)
    local macro_name = params.macro_name;
    local window = MacroWindow.GetWindow(macro_name);
    if (not window) then return end

    -- 模拟事件
    -- print("播放窗口坐标", params.mouse_down_x, params.mouse_down_y, params.mouse_up_x, params.mouse_up_y);
    local mouse_down_x, mouse_down_y = window:WindowPointToScreenPoint(params.mouse_down_x, params.mouse_down_y);
    local mouse_up_x, mouse_up_y = window:WindowPointToScreenPoint(params.mouse_up_x, params.mouse_up_y);
    mouse_up_x, mouse_up_y = mouse_up_x + params.win_offset_x, mouse_up_y + params.win_offset_y;
    window:OnEvent("onmousedown", {mouse_x = mouse_down_x, mouse_y = mouse_down_y, mouse_button = params.mouse_button, buttons_state = params.buttons_state});
    if (params.mouse_down_up_distance > 4) then 
        window:OnEvent("onmousemove", {mouse_x = mouse_down_x + (params.mouse_up_x > params.mouse_down_x and 4 or -4), mouse_y = mouse_down_y, mouse_button = params.mouse_button, buttons_state = params.buttons_state});
        window:OnEvent("onmousemove", {mouse_x = mouse_up_x, mouse_y = mouse_up_y, mouse_button = params.mouse_button, buttons_state = params.buttons_state});
    end
    window:OnEvent("onmouseup", {mouse_x = mouse_up_x, mouse_y = mouse_up_y, mouse_button = params.mouse_button, buttons_state = params.buttons_state});
    -- print("播放屏幕坐标", mouse_down_x, mouse_down_y, mouse_up_x, mouse_up_y);
end

function Macros.UIWindowClickTrigger(params)
    local macro_name = params.macro_name;
    local window = MacroWindow.GetWindow(macro_name);
    if (not window) then return end
    if (params.mouse_down_up_distance > 4) then 
        -- 拖拽
        local startX, startY = window:WindowPointToScreenPoint(params.mouse_down_x, params.mouse_down_y);
        local endX, endY = window:WindowPointToScreenPoint(params.mouse_up_x, params.mouse_up_y);
        endX, endY = endX + params.win_offset_x, endY + params.win_offset_y;
        -- print("模拟窗口坐标", params.mouse_down_x, params.mouse_down_y, params.mouse_up_x, params.mouse_up_y);
        -- print("模拟屏幕坐标", startX, startY, endX, endY);
        return SetDragTrigger(startX, startY, endX, endY, params.mouse_button);
    else
        -- 点击
        local x, y = window:WindowPointToScreenPoint(params.mouse_down_x, params.mouse_down_y);
        return SetClickTrigger(x, y, params.mouse_button);
    end
end

-- 监听处理事件
function MacroWindow.HandleEvent(event_type, window)
    local macro_name = window:GetMacroName();
    if (not macro_name or not Macros:IsRecording()) then return end

    if (event_type == "ondraw") then return end

    if (event_type == "onmousedown") then 
        mouse_down_x, mouse_down_y = ParaUI.GetMousePosition(); 
        mouse_down_win_x, mouse_down_win_y = window:ScreenPointToWindowPoint(mouse_down_x, mouse_down_y);                                  -- 窗口坐标为虚拟的绝对坐标, 不启用窗口自动缩放, 该不会变化
        win_x, win_y = window:GetScreenPosition();
        mouse_buttons_state = GetButtonsState();
    end
    
    if (event_type == "onmouseup") then 
        mouse_up_x, mouse_up_y = ParaUI.GetMousePosition();
        mouse_up_win_x, mouse_up_win_y = window:ScreenPointToWindowPoint(mouse_up_x, mouse_up_y);
        local new_win_x, new_win_y = window:GetScreenPosition();
        local offset_x, offset_y = new_win_x - win_x, new_win_y - win_y;
        -- print("录制屏幕坐标", mouse_down_x, mouse_down_y, mouse_up_x, mouse_up_y);
        local mouse_down_up_distance = math.max(math.abs(mouse_up_x - mouse_down_x), math.abs(mouse_up_y - mouse_down_y));         -- 距离为屏幕距离
        -- print("录制窗口坐标", mouse_down_win_x, mouse_down_win_y, mouse_up_win_x, mouse_up_win_y);
        
        AddMacro("UIWindowClick", {
            macro_name = macro_name,
            mouse_button = mouse_button, 
            buttons_state = mouse_buttons_state, 
            mouse_down_x = mouse_down_win_x, 
            mouse_down_y = mouse_down_win_y, 
            mouse_up_x = mouse_up_win_x, 
            mouse_up_y = mouse_up_win_y, 
            win_offset_x = offset_x, 
            win_offset_y = offset_y, 
            mouse_down_up_distance = mouse_down_up_distance,
        });  -- 为方便扩展, 参数尽量使用对象
    end

end

function MacroWindow.SetWindow(name, window)
    if (not name) then return end
    windows[name] = window;
end

function MacroWindow.GetWindow(name)
    if (not name) then return end
    return windows[name];
end