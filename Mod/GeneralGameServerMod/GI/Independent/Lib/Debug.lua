
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
Debug:Property("StartBeforeCallBack");
Debug:Property("StartAfterCallBack");
Debug:Property("TrackerCallBack");                         -- 当前执行信息回调 
Debug:Property("SuspendBeforeCallBack");                   -- 挂起前回调
Debug:Property("SuspendAfterCallBack");                    -- 挂起后回调

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

    self:RefreshUI();
    
    local callback = self:GetSuspendBeforeCallBack();
    if (type(callback) == "function") then callback() end 

    self:SetCoroutine(__coroutine_running__());
    while (self:IsSuspended()) do
        sync_run(__coroutine_yield__());
	end

    local callback = self:GetSuspendAfterCallBack();
    if (type(callback) == "function") then callback() end 
end

function Debug:Continue()
    self:SetSuspended(false);
    local __co__ = self:GetCoroutine();
    self:SetCoroutine(nil);
    if (__co__) then __coroutine_resume__(__co__, null_function) end 
end

function Debug:Tracker(...)
    local callback = self:GetTrackerCallBack();
    if (type(callback) == "function") then callback(...) end 

    self:StepBreakPoint();
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
    if (not self:IsRunning()) then return end 
    
    self:SetStepSuspend(true);
    self:Continue();
end

function Debug:Run()
    if (not self:IsRunning()) then return end 
    
    self:SetStepSuspend(false);
    self:Continue();
end

function Debug:Start(is_debug, is_step_run)
    self:SetRunning(true);
    self:SetDebug(is_debug);
    self:SetCoroutine(nil);

    self.__vars__ = {};
    self.__var_stack__ = {};         -- 变量集堆栈

    local callback = self:GetStartBeforeCallBack();
    if (type(callback) == "function") then callback(is_debug) end 

    if (is_step_run) then
        self:StepRun();
    else
        self:Run();
    end
    
    local callback = self:GetStartAfterCallBack();
    if (type(callback) == "function") then callback(is_debug) end 
end

function Debug:Stop()
    if (not self:IsRunning()) then return end 

    self:SetDebug(false);
    self:SetRunning(false);
    self:SetStepSuspend(false);
    self:Continue();
end

function Debug:ShowUI(opts)
    if (self.__ui__) then return end 

    opts = opts or {};
    local x, y, width, height = opts.x or 0, opts.y or 0, opts.width or 340, opts.height or 320;
    
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
end

function Debug:RefreshUI()
    if (self.__ui__) then self.__ui__:Refresh() end 
end

function Debug:CloseUI()
    if (self.__ui__) then self.__ui__:CloseWindow() end 
    self.__ui__ = nil;
end

Debug:InitSingleton();

function __debug_tracker__(...)
    Debug:Tracker(...)
end

function __debug_tracker_callback__(callback)
    Debug:SetTrackerCallBack(callback);
end

function __debug_suspend_before_callback__(callback)
    Debug:SetSuspendBeforeCallBack(callback);
end

function __debug_suspend_after_callback__(callback)
    Debug:SetSuspendAfterCallBack(callback);
end

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

function __debug_show_ui__(opts)
    return Debug:ShowUI(opts)
end

function __debug_close_ui__()
    Debug:CloseUI();
end

function __debug_start_before_callback__(callback)
    Debug:SetStartBeforeCallBack(callback);
end

function __debug_start_after_callback__(callback)
    Debug:SetStartAfterCallBack(callback);
end