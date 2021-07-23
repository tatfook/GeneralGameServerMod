--[[
Title: ThreadHelper
Author(s): wxa
Date: 2020/6/10
Desc: 线程辅助类, 用于线程通信
use the lib: 
-------------------------------------------------------
local ThreadHelper = NPL.load("Mod/GeneralGameServerMod/CommonLib/ThreadHelper.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/System.lua");

local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local ThreadHelper = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ThreadHelper:Property("NeuronFile", "Mod/GeneralGameServerMod/CommonLib/ThreadHelper.lua")
ThreadHelper:Property("WorkerThreadName", "WorkerThread");      -- 默认线程名前缀
ThreadHelper:Property("WorkerThreadCount", 0);                  -- 线程数量
ThreadHelper:Property("ThreadName");                            -- 当前线程名

local __event_emitter__ = EventEmitter:new();
local __main_thread_name__ = "main";


function ThreadHelper:ctor()
    self:SetThreadName(__rts__:GetName());
end

function ThreadHelper:GetTheadNameByWorkerThreadIndex(index)
    return string.format("%s%s", self:GetWorkerThreadName(), self:GetWorkerThreadCount());
end

function ThreadHelper:IsMainThread()
    return __rts__:GetName() == __main_thread_name__;
end

-- 创建工作线程
function ThreadHelper:StartWorkerThread(thread_name)
    if (not self:IsMainThread()) then return end 

    self:SetWorkerThreadCount(self:GetWorkerThreadCount() + 1);
    thread_name = thread_name or self:GetTheadNameByWorkerThreadIndex();

    NPL.CreateRuntimeState(thread_name, 0):Start();

    return self:GetWorkerThreadCount(); 
end

function ThreadHelper:GetRemoteAddress(thread_name)
    return string.format("(%s)%s", thread_name or __main_thread_name__, self:GetNeuronFile());
end

-- 工作线程转主线程发送信息
function ThreadHelper:SendMsgToMainThread(data, cmd)
    self:SendMsgToWorkerThread(__main_thread_name__, data, cmd);
end

-- 信息同步至工作线程
function ThreadHelper:SendMsgToWorkerThread(thread_name, data, cmd)
    thread_name = thread_name or __main_thread_name__;

    local msg = {
        __cmd__ = cmd or "__msg__",
        __from_thread_name__ = self:GetThreadName(),
        __to_thread_name__ = thread_name, 
        __data__ = data,
    };

    if (thread_name == self:GetThreadName()) then 
        self:OnActivate(msg);
    else
        NPL.activate(self:GetRemoteAddress(thread_name), msg);
    end
end

-- 处理通信消息
function ThreadHelper:HandleMsg(msg)
    __event_emitter__:TriggerEventCallBack("__msg__", msg);
end

function ThreadHelper:OnMsg(callback)
    __event_emitter__:RegisterEventCallBack("__msg__", callback);
end

-- 激活函数
function ThreadHelper:OnActivate(msg)
    if (type(msg) ~= "table") then return end
    
    -- 提取内置数据
    -- local __from_thread_name__, __to_thread_name__, __cmd__, __data__ = msg.__from_thread_name__, msg.__to_thread_name__, msg.__cmd__, msg.__data__;

    -- 线程初始化
    self:HandleMsg(msg);
end

--单列模式
ThreadHelper:InitSingleton();

NPL.this(function()
    ThreadHelper:OnActivate(msg);
end);