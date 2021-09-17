
--[[
Title: Debug
Author(s):  wxa
Date: 2021-06-01
Desc: Debug
use the lib:
------------------------------------------------------------
local Debug = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Debug.lua");
------------------------------------------------------------
]]

local Debug = inherit(ToolBase, module("Debug"));

Debug:Property("Debug", false, "IsDebug");                 -- 是否调试
Debug:Property("Running", false, "IsRunning");             -- 是否在运行
Debug:Property("Coroutine");                               -- 当前协程
Debug:Property("Suspended", false, "IsSuspended");         -- 是否挂起
Debug:Property("StepSuspend", false, "IsStepSuspend");     -- 是否单步挂起

function Debug:ctor()
    self.__vars__ = {};              -- 变量集
    self.__var_stack__ = {};         -- 变量集堆栈
    self.__ui__ = nil;               -- ui 对象
end

-- 添加观察键值对
function Debug:AddWatchKeyValue(key, val)
    self.__vars__[key] = val;
    self:RefreshUI();
end

function Debug:Suspend()
    if (not self:IsSuspended() or not self:IsDebug()) then return end 

    self:SetCoroutine(__coroutine_running__());

    self:ShowUI();
    while (self:IsSuspended()) do 
        sync_run(__coroutine_yield__());
	end
end

function Debug:Continue()
    self:SetSuspended(false);
    local __co__ = self:GetCoroutine();
    self:SetCoroutine(nil);
    if (__co__) then __coroutine_resume__(__co__, null_function) end 
end

function Debug:StepBreakPoint()
    self:SetSuspended(self:IsStepSuspend());
    self:Suspend();
end

function Debug:BreakPoint()
    self:SetSuspended(true);
    self:Suspend();
end

function Debug:StepRun()
    self:SetStepSuspend(true);
    self:Continue();
end

function Debug:Run()
    self:SetStepSuspend(false);
    self:Continue();
end

function Debug:Start(is_debug, is_step_run)
    self:SetDebug(is_debug);
    self:SetRunning(true);
    self.__vars__ = {};
    self.__var_stack__ = {};         -- 变量集堆栈
    if (is_step_run) then
        self:StepRun();
    else
        self:Run();
    end
end

function Debug:Stop()
    if (not self:IsRunning()) then return end 

    self:CloseUI();
    self:SetDebug(false);
    self:SetRunning(false);
    self:SetStepSuspend(false);
    self:Continue();
    -- __coroutine_exit__();
    -- __error__("__debug_stop__");
end

function Debug:ShowUI(G)
    if (not self:IsDebug()) then return end 

    G = G or {};
    local x, y, width, height = G.x or 0, G.y or 0, G.width or 340, G.height or 320;
    if (self.__ui__) then x, y, width, height = self.__ui__:GetNativeWindow():GetAbsPosition() end
    self:CloseUI();
    local cur_vars = self.__vars__;
    for index, var in ipairs(self.__var_stack__) do
        if (cur_vars[var.key] ~= var.value) then
            for i = index, #(self.__var_stack__) do 
                self.__var_stack__[i] = nil;
            end
            break;
        else 
            cur_vars = var.value;
        end
    end
    self.__ui__ = ShowWindow({
        __vars__ = self.__vars__,
        __var_stack__ = self.__var_stack__,
    }, {
        url = "%gi%/Independent/UI/Debug.html",
        alignment = "_lt",
        x = x, y = y, width = width, height = height,
        draggable = true,
    });
    self.__ui__:GetNativeWindow():Reposition("_lt", x, y, width, height);
end

function Debug:RefreshUI()
    if (self.__ui__) then self:ShowUI() end 
end

function Debug:CloseUI()
    if (self.__ui__) then self.__ui__:CloseWindow() end 
    self.__ui__ = nil;
end

Debug:InitSingleton();

function __debug_step_break_point__()
    Debug:StepBreakPoint();
end

function __debug_break_point__()
    Debug:BreakPoint();
end

function __debug_step_run__()
    Debug:StepRun();
end

function __debug_run__()
    Debug:Run();
end

function __debug_start__(is_debug, is_step_run)
    Debug:Start(is_debug, is_step_run);
end

function __debug_stop__()
    Debug:Stop();
end

function __debug_add_watch_key_value__(key, val)
    Debug:AddWatchKeyValue(key, val);
end
