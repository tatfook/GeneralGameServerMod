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
	-- 加载内置模块
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
	local text = Helper.ReadFile(filename);
	if (not text or text == "") then return end
	local code_func, errormsg = loadstring(text, "loadstring:" .. Helper.FormatFilename(filename));
	if errormsg then
		return GGS.INFO("Independent:LoadFile LoadString Failed", Helper.FormatFilename(filename), errormsg);
	end
	
	-- 设置代码环境
	setfenv(code_func, self:GetCodeEnv());
	
	-- 执行代码
	self:Call(code_func);
end

function Independent.Load(files)
	for _, filename in ipairs(files) do
		self:LoadFile(filename);
	end
end

function Independent:Call(func, ...)
	if (type(func) ~= "function") then return false end

	return xpcall(func, function (err) 
		GGS.INFO("Independent:Call:Error", err);
	end, ...);
end

function Independent:CallEventCallBack(eventType)
	local CodeEnv = self:GetCodeEnv();
	local __event_callback__ = CodeEnv.__event_callback__[eventType];
	if (not __event_callback__) then return end
	for _, callback in pairs(__event_callback__) do
		if (not self:Call(callback)) then
			self:Stop();
		end
	end
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
	if (type(rawget(CodeEnv, "main")) == "function") then
		if (not self:Call(CodeEnv.main)) then 
			self:Stop();
			return ;
		end
	end

	-- 开始定时器
	self:GetLoopTimer():Change(LoopTickCount, LoopTickCount);
	
	-- 设置运行标识
	self:SetRunning(true);
end

function Independent:Tick()
	local CodeEnv = self:GetCodeEnv();
	
	-- 触发定时回调
	self:CallEventCallBack(CodeEnv.EventType.LOOP);

	-- 触发 LOOP 快捷回调
	if (type(rawget(CodeEnv, "loop")) ~= "function") then return end
	if (not self:Call(CodeEnv.loop, CodeEnv.TickEvent:Init())) then self:Stop() end
end

function Independent:Stop()
	local CodeEnv = self:GetCodeEnv();
	if (not CodeEnv) then return end
	
	print("====================Independent:Stop=====================");

	self:CallEventCallBack(CodeEnv.EventType.CLEAR);

	if (type(rawget(CodeEnv, "clear")) == "function") then 
		self:Call(CodeEnv.clear);
	end

	GameLogic.ActivateDefaultContext();

	if (self:GetLoopTimer()) then
		self:GetLoopTimer():Change();
		self:SetLoopTimer(nil);
	end
	
	CodeEnv:Clear();

	self:SetRunning(false);

	-- collectgarbage("collect");
end

Independent:InitSingleton():Init();