--[[
Title: ThreadHelper
Author(s): wxa
Date: 2020/6/10
Desc: 线程辅助类
use the lib: 
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/ThreadHelper.lua");
local ThreadHelper = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.ThreadHelper");
-------------------------------------------------------
]]


local ThreadHelper = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ThreadHelper:Property("WorkerThreadName", "WorkerThread");
ThreadHelper:Property("WorkerThreadCount", 0);

function ThreadHelper:ctor()
end

function ThreadHelper:StartWorkerThread(workerThreadCount)
    workerThreadCount = workerThreadCount or 1;
    NPL.CreateRuntimeState(threadName, 0):Start(); 
end

--单列模式
ThreadHelper:InitSingleton();
