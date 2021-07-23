--[[
Title: Independent
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Independent = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Independent.lua");
Independent:Start("%gi%/Independent/Example/Empty.lua");
------------------------------------------------------------
]]
local Helper = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Helper.lua", IsDevEnv);
local CodeEnv = NPL.load("./CodeEnv.lua", IsDevEnv);

local Independent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Independent:Property("CodeEnv");                              -- 代码环境
Independent:Property("Running", false, "IsRunning");          -- 是否在运行
Independent:Property("LoopTimer");                            -- 循环定时器
Independent:Property("LoopTickCount", 20);                    -- 主循环频率
Independent:Property("ErrorExit", true, "IsErrorExit");       -- 出错退出
Independent:Property("ShareMouseKeyBoard", false, "IsShareMouseKeyBoard");            -- 是否共享鼠标键盘事件
Independent:Property("MainFileName");                         -- 入口文件

local coroutine_running = coroutine.running;
local coroutine_status = coroutine.status;
local coroutine_yield = coroutine.yield;
local coroutine_resume = coroutine.resume;

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
	-- 已经开始执行了则不能初始化
	if (self:GetCodeEnv() or self:IsRunning()) then return end
	
	-- 重置定时器
	self:SetLoopTimer(commonlib.Timer:new({callbackFunc = function()
		self:Tick();
	end}));

	-- 创建执行协同程序
	local __args__ = {};
	self.__co__ = coroutine.create(function(...)
		self:Pack(__args__, ...);
		local callback = self:Select(1, __args__);
		while(type(callback) == "function") do
			self:XPCall(callback, self:Select(2, __args__));
			self:Pack(__args__, coroutine_yield());
			callback = self:Select(1, __args__);
		end
	end);

	-- 加载内置模块
	self.__files__ = {};

	-- 设置环境
	self:SetCodeEnv(CodeEnv:new():Init(self));

	return self;
end

-- 重置环境
function Independent:Reset()
	self:Stop();
	self:Init();
	self:Start(self:GetMainFileName());
end

function Independent:LoadInnerModule()
	local func = loadstring([[
local System = require("System");
local Log = require("Log");
local State = require("State");
local Timer = require("Timer");
local Scene = require("Scene");
local API = require("API");
	]]);
	setfenv(func, self:GetCodeEnv());
	self:Call(func); 
end

function Independent:IsLoaded(filename)
	for i = 1, #self.__files__ do
		if (self.__files__[i] == filename) then return true end
	end
	return false;
end

function Independent:LoadString(text, filename)
	filename = filename or ParaMisc.md5(text);

	-- 生成防止重复执行代码, 未知原因会重复执行
	local header_text = string.format([[
		local __filename__ = "%s";
		if (__modules__[__filename__]) then return end
		__modules__[__filename__] = {__filename__ = __filename__, __loaded__ = false, __module__ = nil};

		local function module(__name__, __module__)
			__module__ = __module__ or __name__;
			if (type(__module__) ~= "table") then __module__ = {} end 
			if (type(__name__) ~= "string") then __name__ = __filename__ end 
			__modules__[__filename__].__module__ = __module__;
			__modules__[__filename__].__name__ = __name__;
			return __module__;
		end
	]], filename);
	
	local tail_text = [[__modules__[__filename__].__loaded__ = true;]]
	text = header_text .. "\n" .. text .. "\n" .. tail_text;

	-- 生成函数
	local code_func, errormsg = loadstring(text, "loadstring:" .. filename);
	if errormsg then return GGS.INFO("Independent:LoadFile LoadString Failed", filename, errormsg) end

	-- 设置代码环境
	setfenv(code_func, self:GetCodeEnv());
	
	-- 执行代码
	self:Call(code_func);

	self.__files__[#self.__files__ + 1] = filename;

	return self:GetCodeEnv().__modules__[filename].__module__;
end

function Independent:LoadFile(filename)
	if (not filename or not self:IsRunning() or self:IsLoaded(filename)) then return end
	
	local text = Helper.ReadFile(filename);
	if (not text or text == "") then return end

	return self:LoadString(text, Helper.FormatFilename(filename));
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
	end, ...);
end

function Independent:Call(...)
	local callback = select(1, ...);
	if (type(callback) ~= "function") then return false end
	local ok = nil;
	if (self:IsCodeEnv()) then 
		ok, err = self:XPCall(callback, select(2, ...));
	else
		ok, err = self:Resume(...);
	end
	-- 出错是否停止沙盒
	if (not ok) then 
		print("Error:", err, self.__co__ == coroutine_running(), self.__co__ and coroutine.status(self.__co__));
		if (self:IsErrorExit()) then
			self:Stop() 
		end
	end
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
	local co, isMainThread = coroutine_running();
	local status = self.__co__ and coroutine_status(self.__co__);
	-- 不是主线程, 默认协程处于活跃状态则以当前环境执行
	return not isMainThread and (co == self.__co__ or status == "running" or status == "normal");
	-- return co == self.__co__ or status == "running" or status == "normal";
end

function Independent:Yield(...)
	self:Call(coroutine_yield(...));
end

function Independent:Resume(...)
	return self.__co__ and coroutine_resume(self.__co__, ...);
end

function Independent:Restart()
	self:Reset();
end

function Independent:Start(filename)
	if (self:IsRunning()) then return end
	print("====================Independent:Start=====================");
	-- 确保已初始化
	self:Init();

	-- 设置运行标识
	self:SetRunning(true);
	self:SetMainFileName(filename);

	-- 先加载内部模块
	self:LoadInnerModule();

	-- 再加载入口文件
	self:LoadFile(self:GetMainFileName());

	-- 激活上下文环境
	local CodeEnv = self:GetCodeEnv();

	-- 如果独占鼠标键盘则接管Context
	if (not self:IsShareMouseKeyBoard()) then
		CodeEnv.SceneContext:activate();
	end

	-- 触发 MAIN 事件回调
	self:CallEventCallBack(CodeEnv.EventType.MAIN);

	-- 调用 快捷方式 MAIN
	self:Call(rawget(CodeEnv, "main"));

	-- 开始定时器
	local loopTickCount = self:GetLoopTickCount();
	self:GetLoopTimer():Change(loopTickCount, loopTickCount);
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

	CodeEnv.SceneContext:Inactivate();

	CodeEnv:Clear();

	self:SetCodeEnv(nil);

	self:Resume();  -- 使用空值退出协同程序
	self.__co__ = nil;
	-- collectgarbage("collect");
end


function Independent:OnWorldLoaded()
end

function Independent:OnWorldUnloaded()
    self:Stop();
end

Independent:InitSingleton();

-- local last_time = ParaGlobal.timeGetTime();
-- function Independent:OnCameraFrameMove()
-- 	local cur_time = ParaGlobal.timeGetTime();
-- 	print(cur_time - last_time)
-- 	last_time = cur_time;
-- end

-- commonlib.setfield("__independent__", Independent);
-- local attr = ParaCamera.GetAttributeObject();
-- attr:SetField("On_FrameMove", ";__independent__.OnCameraFrameMove();");