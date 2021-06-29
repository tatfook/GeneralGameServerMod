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


local ThreadHelper = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ThreadHelper:Property("NeuronFile", "Mod/GeneralGameServerMod/Core/Server/ThreadHelper.lua")
ThreadHelper:Property("WorkerThreadName", "WorkerThread");
ThreadHelper:Property("WorkerThreadCount", 0);
ThreadHelper:Property("ThreadName"); 

function ThreadHelper:ctor()
    self:SetThreadName(__rts__:GetName());
end

function ThreadHelper:GetTheadNameByWorkerThreadIndex(index)
    return string.format("%s%s", self:GetWorkerThreadName(), self:GetWorkerThreadCount());
end

function ThreadHelper:IsMainThread()
    return __rts__:GetName() == "main";
end

function ThreadHelper:StartWorkerThread()
    if (not self:IsMainThread()) then return end 

    self:SetWorkerThreadCount(self:GetWorkerThreadCount() + 1);
    NPL.CreateRuntimeState(self:GetTheadNameByWorkerThreadIndex(), 0):Start();
    return self:GetWorkerThreadCount(); 
end

function ThreadHelper:GetRemoteAddress(thread_name, nid, neuron_file)
    return string.format("(%s)%s:%s", thread_name or "main", nid or "", neuron_file or self:GetNeuronFile());
end

-- 工作线程转主线程发送信息
function ThreadHelper:SendMsgToMainThread(msg)
	if (self:IsMainThread()) then return self:OnActivate(msg) end

    NPL.activate(self:GetRemoteAddress(), msg);
end

-- 信息同步至工作线程
function ThreadHelper:SendMsgToWorkerThread(msg)
    if (self:IsMainThread()) then return end
    if (type(msg) ~= "table" and not msg.__thead_name__) then return end

    NPL.activate(self:GetRemoteAddress(msg.__thead_name__), msg);
end

-- 激活函数
function ThreadHelper:OnActivate(msg)
    if (type(msg) ~= "table") then return end
end

--单列模式
ThreadHelper:InitSingleton();

NPL.this(function()
    ThreadHelper:OnActivate(msg);
end);