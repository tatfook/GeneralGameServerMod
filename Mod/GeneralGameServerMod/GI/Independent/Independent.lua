--[[
Title: Independent
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Independent = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Independent.lua");
Independent:LoadFile("%gi%/Independent/Example/Empty.lua");
------------------------------------------------------------
]]
local Helper = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Helper.lua", IsDevEnv);
local CodeEnv = NPL.load("./CodeEnv.lua", IsDevEnv);

local Independent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Independent:Property("CodeEnv");                      -- 代码环境
Independent:Property("Running", false, "IsRunning");  -- 是否在运行
Independent:Property("LoopTimer");                    -- 循环定时器
local LoopTickCount = 20;                             -- 定时器频率

local function null_function() end 

function Independent:Pack(args, ...)
	args = type(args) == "table" and args or {};
    args.n = select("#", ...);
	for i = 1, 20 do args[i] = nil end
    for i = 1, args.n do
        args[i] = select(i, ...);
    end
    return args;
end

function Independent:Select(index, args)
	index = index or 1;
    return args[index], args[index + 1], args[index + 2], args[index + 3], args[index + 4], args[index + 5], args[index + 6], args[index + 7], args[index + 8], args[index + 9];
end

function Independent:ctor()
end

-- 初始化函数 
function Independent:Init()
	-- 先清除
	self:Stop();

	-- 设置环境
	self:SetCodeEnv(setmetatable({}, {__index = CodeEnv:new():Init(self)}));

	-- 重置定时器
	self:SetLoopTimer(commonlib.Timer:new({callbackFunc = function()
		Independent:Tick();
	end}));

	-- 创建执行协同程序
	local __args__ = {};
	self.__co__ = coroutine.create(function(...)
		self:Pack(__args__, ...);
		local callback = self:Select(1, __args__);
		while(type(callback) == "function") do
			self:XPCall(callback, self:Select(2, __args__));
			self:Pack(__args__, coroutine.yield());
			callback = self:Select(1, __args__);
		end
	end);

	-- 加载内置模块
	self.__files__ = {};
	self:LoadInnerModule();
	
	return self;
end

function Independent:LoadInnerModule()
	local func = loadstring([[
local Log = require("Log");
local State = require("State");
local Timer = require("Timer");
local Scene = require("Scene");
	]]);
	setfenv(func, self:GetCodeEnv());
	self:Call(func); 
end

function Independent:LoadFile(filename)
	for i = 1, #self.__files__ do
		if (self.__files__[i] == filename) then return end
	end

	local text = Helper.ReadFile(filename);
	if (not text or text == "") then return end
	local code_func, errormsg = loadstring(text, "loadstring:" .. Helper.FormatFilename(filename));
	if errormsg then
		return GGS.INFO("Independent:LoadFile LoadString Failed", Helper.FormatFilename(filename), errormsg);
	end

	-- print("LoadFile:", filename)
	-- if (filename == "%gi%/Independent/Example/Rank.lua") then print(text) end

	-- 设置代码环境
	setfenv(code_func, self:GetCodeEnv());
	
	-- 执行代码
	self:Call(code_func);

	self.__files__[#self.__files__ + 1] = filename;
end

function Independent:Load(files)
	for _, filename in ipairs(files) do
		self:LoadFile(filename);
	end
end

function Independent:XPCall(callback, ...)
	return xpcall(callback, function (err) 
		GGS.INFO("Independent:Call:Error", err);
		DebugStack();
		self:Stop();
	end, ...);
end

function Independent:Call(...)
	local callback = select(1, ...);
	if (type(callback) ~= "function") then return false end
	local ok = nil;
	if (self:IsCodeEnv()) then 
		ok = self:XPCall(callback, select(2, ...));
	else
		ok = self:Resume(...);
	end
	if (not ok) then self:Stop() end
end

function Independent:CallEventCallBack(eventType)
	local CodeEnv = self:GetCodeEnv();
	local __event_callback__ = CodeEnv.__event_callback__[eventType];
	if (not __event_callback__) then return end
	for _, callback in pairs(__event_callback__) do
		self:Call(callback);
	end
end

function Independent:IsCodeEnv()
	local co = coroutine.running();
	return self.__co__ == co;
end

function Independent:Sleep(sleep)
	if (not self:IsCodeEnv()) then return end 

	local CodeEnv = self:GetCodeEnv();
	local SleepLoopCallBack = nil;
	local sleepTo = ParaGlobal.timeGetTime() + sleep;
	local isSleeping = true;
	local function SleepLoopCallBack()
		local curtime = ParaGlobal.timeGetTime();
		isSleeping = curtime < sleepTo;
	end

	CodeEnv.RegisterEventCallBack(CodeEnv.EventType.LOOP, SleepLoopCallBack);
	while (isSleeping) do self:Yield() end
	CodeEnv.RemoveEventCallBack(CodeEnv.EventType.LOOP, SleepLoopCallBack);
end

function Independent:Yield(...)
	self:Call(coroutine.yield(...));
end

function Independent:Resume(...)
	return coroutine.resume(self.__co__, ...);
end

function Independent:Restart()
	local __files__ = self.__files__;
	self:Stop();
	self:Init();
	self:Load(__files__);
	self:Start();
end

function Independent:Start()
	if (self:IsRunning()) then return end
	print("====================Independent:Start=====================");

	-- 激活上下文环境
	local CodeEnv = self:GetCodeEnv();
	CodeEnv.SceneContext:activate();

	-- 触发 MAIN 事件回调
	self:CallEventCallBack(CodeEnv.EventType.MAIN);

	-- 调用 快捷方式 MAIN
	self:Call(rawget(CodeEnv, "main"));

	-- 开始定时器
	self:GetLoopTimer():Change(LoopTickCount, LoopTickCount);
	
	-- 设置运行标识
	self:SetRunning(true);
end

function Independent:Tick()
	local CodeEnv = self:GetCodeEnv();
	if (not CodeEnv) then return end

	-- 触发定时回调
	self:CallEventCallBack(CodeEnv.EventType.LOOP);

	-- 触发 LOOP 快捷回调
	self:Call(rawget(CodeEnv, "loop"));
end

function Independent:Stop()
	local CodeEnv = self:GetCodeEnv();
	if (not CodeEnv or not self:IsRunning()) then return end
	print("====================Independent:Stop=====================");

	self:SetRunning(false);

	if (self:GetLoopTimer()) then
		self:GetLoopTimer():Change();
		self:SetLoopTimer(nil);
	end

	self:CallEventCallBack(CodeEnv.EventType.CLEAR);

	if (type(rawget(CodeEnv, "clear")) == "function") then 
		self:Call(CodeEnv.clear);
	end

	GameLogic.ActivateDefaultContext();
	
	CodeEnv:Clear();

	self:SetCodeEnv(nil);

	self:Resume();  -- 使用空值退出协同程序
	-- collectgarbage("collect");
end

Independent:InitSingleton():Init();