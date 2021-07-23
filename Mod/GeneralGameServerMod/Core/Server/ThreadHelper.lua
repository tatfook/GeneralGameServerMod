--[[
Title: ThreadHelper
Author(s): wxa
Date: 2020/6/10
Desc: 线程辅助类
use the lib: 
-------------------------------------------------------
local ThreadHelper = NPL.load("Mod/GeneralGameServerMod/Core/Server/ThreadHelper.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/System.lua");

local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local ThreadHelper = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ThreadHelper:Property("NeuronFile", "Mod/GeneralGameServerMod/Core/Server/ThreadHelper.lua")
ThreadHelper:Property("WorkerThreadName", "WorkerThread");      -- 默认线程名前缀
ThreadHelper:Property("WorkerThreadCount", 0);                  -- 线程数量
ThreadHelper:Property("ThreadName");                            -- 当前线程名
ThreadHelper:Property("Dirty")

local __event_emitter__ = EventEmitter:new();
local __main_thread_name__ = "main";
local __all_thread_info__ = {};  -- 所有线程信息


function ThreadHelper:ctor()
    self:SetThreadName(__rts__:GetName());
end

function ThreadHelper:GetTheadNameByWorkerThreadIndex(index)
    return string.format("%s%s", self:GetWorkerThreadName(), self:GetWorkerThreadCount());
end

function ThreadHelper:IsMainThread()
    return __rts__:GetName() == __main_thread_name__;
end

function ThreadHelper:OnChange(...)
    __event_emitter__:RegisterEventCallBack("__change__", ...);
end

function ThreadHelper:SetWorkerThreadInfo(thread_name, thread_info)
    commonlib.partialcopy(self:GetWorkerThreadInfo(thread_name), thread_info);
    __event_emitter__:TriggerEventCallBack("__change__", thread_info);
end

function ThreadHelper:GetWorkerThreadInfo(thread_name)
    __all_thread_info__[thread_name] = __all_thread_info__[thread_name] or {};
    return __all_thread_info__[thread_name];
end

function ThreadHelper:SetThreadInfo(info)
    self:SetWorkerThreadInfo(self:GetThreadName(), info);

    if (not self:IsMainThread()) then
        self:SendMsgToMainThread(info, "__set_thread_info__")
    end
end

function ThreadHelper:GetThreadInfo()
    return self:GetWorkerThreadInfo(self:GetThreadName());
end

function ThreadHelper:GetAllThreadInfo()
    return __all_thread_info__;
end

-- 创建工作线程
function ThreadHelper:StartWorkerThread(thread_name)
    if (not self:IsMainThread()) then return end 

    self:SetWorkerThreadCount(self:GetWorkerThreadCount() + 1);
    thread_name = thread_name or self:GetTheadNameByWorkerThreadIndex();

    print("=======================create worker thread==========================", thread_name);
    NPL.CreateRuntimeState(thread_name, 0):Start();

    local thread_info = {
        __index__ = self:GetWorkerThreadCount(), 
    }
    -- 主线程设置线程信息
    self:SetWorkerThreadInfo(thread_name, thread_info);
    -- 新线程设置线程信息
    self:SendMsgToWorkerThread(thread_name, thread_info, "__set_thread_info__");

    return self:GetWorkerThreadCount(); 
end

function ThreadHelper:GetRemoteAddress(thread_name)
    return string.format("(%s)%s", thread_name or __main_thread_name__, self:GetNeuronFile());
end

-- 工作线程转主线程发送信息
function ThreadHelper:SendMsgToMainThread(data, cmd)
    local msg = {
        __cmd__ = cmd or "__msg__",
        __from_thread_name__ = self:GetThreadName(),
        __to_thread_name__ = __main_thread_name__,
        __data__ = data,
    }
    if (self:IsMainThread()) then return self:OnActivate(msg) end
    NPL.activate(self:GetRemoteAddress(), msg);
end

-- 信息同步至工作线程
function ThreadHelper:SendMsgToWorkerThread(thread_name, data, cmd)
    if (not thread_name) then return end

    local msg = {
        __cmd__ = cmd or "__msg__",
        __from_thread_name__ = self:GetThreadName(),
        __to_thread_name__ = thread_name, 
        __data__ = data,
    };

    if (thread_name == self:GetThreadName()) then return self:OnActivate(data) end

    NPL.activate(self:GetRemoteAddress(thread_name), msg);
end

-- 处理通信消息
function ThreadHelper:HandleMsg(msg)
end

-- 激活函数
function ThreadHelper:OnActivate(msg)
    if (type(msg) ~= "table") then return end
    
    -- 提取内置数据
    local __from_thread_name__, __to_thread_name__, __cmd__, __data__ = msg.__from_thread_name__, msg.__to_thread_name__, msg.__cmd__, msg.__data__;

    -- 线程初始化
    if (__cmd__ == "__set_thread_info__") then
        local __thread_name__ = __from_thread_name__ == __main_thread_name__ and __to_thread_name__ or __from_thread_name__;
        -- print("================================set thread info==============================", __thread_name__);
        self:SetWorkerThreadInfo(__thread_name__, __data__);
    else 
        self:HandleMsg(__data__);
    end
end

--单列模式
ThreadHelper:InitSingleton();

NPL.this(function()
    ThreadHelper:OnActivate(msg);
end);