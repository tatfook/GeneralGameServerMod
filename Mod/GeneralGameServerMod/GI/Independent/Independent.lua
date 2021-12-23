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

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local CodeEnv = NPL.load("./CodeEnv.lua", IsDevEnv);

local Independent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Independent:Property("CodeEnv");                              -- 代码环境
Independent:Property("Running", false, "IsRunning");          -- 是否在运行
Independent:Property("LoopTimer");                            -- 循环定时器
Independent:Property("LoopTickCount", 50);                    -- 主循环频率 每秒50帧
Independent:Property("ErrorExit", true, "IsErrorExit");       -- 出错退出
Independent:Property("ShareMouseKeyBoard", false, "IsShareMouseKeyBoard");            -- 是否共享鼠标键盘事件
Independent:Property("MainFileName");                                                 -- 入口文件
Independent:Property("TickCount", 0);                                                 -- tick 次数
Independent:Property("TickSpeed", 1);                                                 -- 设置Tick速度

function Independent:ctor()
	self:SetShareMouseKeyBoard(true);
end

-- 初始化函数 
function Independent:Init()
	-- 已经开始执行了则不能初始化
	if (self:GetCodeEnv() or self:IsRunning()) then return end
	
	-- 重置定时器
	self:SetLoopTimer(commonlib.Timer:new({callbackFunc = function()
		self:Tick();
	end}));

	-- 加载内置模块
	self.__files__ = {};

	-- 所有模块环境
	self.__module_env_list__ = {};

	-- 路径映射
	self.__alias_path_map__ = {
		["gi"] = "Mod/GeneralGameServerMod/GI",
		["lib"] = "Mod/GeneralGameServerMod/GI/Independent/Lib",
	};

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
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/List.lua");
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/Coroutine.lua");
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/Debug.lua");
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/System.lua");
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/Log.lua");
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/State.lua");
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/Timer.lua");
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/Scene.lua");
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/UI.lua");
	self:LoadFile("Mod/GeneralGameServerMod/GI/Independent/Lib/API.lua");
end

function Independent:IsLoaded(filename)
	return self.__files__[filename];
end

function Independent:GetModuleEnv(__module__)
	__module__ = __module__ or {};

	local __default_directory__ = "Mod/GeneralGameServerMod/GI/Independent/Lib"; 
	local __filename__ = __module__.__filename__ or "";
	local __directory__ = string.gsub(__filename__, "[^/\\]*$", "");
	local __module_env__ = {
		__module__ = __module__,
		__filename__ = __filename__,
		__directory__ = __directory__,
		__code_env__ = self:GetCodeEnv(),
	}
	
	__module_env__.module = function() 
		return __module__.__module__;
	end
	__module_env__.loadfile = function(path)
		return self:LoadFile(path);
	end
	__module_env__.require = function(path)
		if (string.match(path, "^[A-Za-z]")) then 
			path = string.format("%s/%s.lua", __default_directory__, path);
		else 
			path = __module_env__.__code_env__.GetFullPath(path, __directory__);
		end
		if (not string.match(path, "%.lua$")) then path = path .. ".lua" end 
		return self:LoadFile(path);
	end
	
	__module_env__.__module_env__ = __module_env__;
	__module__.__module_env__ = __module_env__;
	table.insert(self.__module_env_list__, __module_env__);

	return setmetatable(__module_env__, {
		__index = function(t, key) 
			if (key == "__module__") then return __module__ end 
			return __module_env__.__code_env__[key];
		end,
		__newindex = function(t, key, val)
			if (key == "__module__") then return end 
			__module_env__.__code_env__[key] = val;
		end
	});
end

function Independent:LoadString(text, filename)
	local CodeEnv = self:GetCodeEnv();
	local __modules__ = CodeEnv.__modules__;

	local __filename__ = filename or ParaMisc.md5(text);
	__filename__ = string.gsub(__filename__, "\\", "/");

	-- 已加载完成直接返回
	if (__modules__[__filename__] and __modules__[__filename__].__loaded__) then return __modules__[__filename__].__module__ end

	-- 加载中则等待
	if (__modules__[__filename__] and not __modules__[__filename__].__loaded__) then 
		while (not __modules__[__filename__].__loaded__) do CodeEnv.sleep() end 	
		return __modules__[__filename__].__module__;
	end

	-- 初始化模块
	local __module__ = {__filename__ = __filename__, __loaded__ = false, __module__ = {}};
	__modules__[__filename__] = __module__;

	-- 生成函数
	local code_func, errormsg = loadstring(text .. "\n__module__.__loaded__ = true;", "loadstring:" .. __filename__);
	if errormsg then return print("Independent:LoadString Failed", __filename__, errormsg) end

	-- 设置代码环境
	setfenv(code_func, self:GetModuleEnv(__module__));
	
	-- 执行代码
	self:Call(code_func);

	-- 等待执行完成
	while (not __module__.__loaded__) do CodeEnv.sleep() end 	
	
	
	if (filename) then 
		print("========================loadfile=======================", filename);
		-- 添加至加载列表
		self.__files__[filename] = __module__;
	else
		-- print("========================exe text code=====================", text);
		-- 纯代码不保存模块
		__modules__[__filename__] = nil;
	end 

	-- 返回模块
	return __module__.__module__;
end

local inject_map = {
	{"^(%s*function%A+[^%)]+%)%s*)$", "%1 __checkyield__();"},
	{"^(%s*local%s+function%W+[^%)]+%)%s*)$", "%1 __checkyield__();"}, 
	{"^(%s*for%s.*%s+do%s*)$", "%1 __checkyield__();"},
	{"^(%s*while%A.*%Ado%s*)$", "%1 __checkyield__();"},
	{"^(%s*repeat%s*)$", "%1 __checkyield__();"},
}
function Independent:InjectCheckYieldToCode(code, filename)
	local lines = {};
	local isInLongString

	filename = filename or ParaMisc.md5(code);
	local function injectLine_(line, key)
		local old_line = line;
		for i,v in ipairs(inject_map) do
			line = string.gsub(line, v[1], v[2]);
		end
		if (string.match(line, ";%s*")) then
			line = line .. string.format(" __fileline__('%s', %s, '%s');", filename, #lines + 1, CommonLib.EncodeBase64(old_line));
		end
		return line;
	end

	for line in string.gmatch(code or "", "([^\r\n]*)\r?\n?") do
		if(isInLongString) then
			lines[#lines+1] = line;	
			isInLongString = line:match("%]%]") == nil;
		else
			isInLongString = line:match("%[%[[^%]]*$") ~= nil;
			lines[#lines+1] = injectLine_(line);	
		end
	end
	code = table.concat(lines, "\n");
	return code;
end
	
function Independent:LoadFile(filename)
	if (not filename or not self:IsRunning()) then return end
	local filepath = CommonLib.GetFullPath(filename, self.__alias_path_map__);
	if (self.__files__[filepath]) then return self.__files__[filepath].__module__ end 

	local text = CommonLib.GetFileText(filepath);
	if (not text or text == "") then 
		print("file not exist: ", filepath);
		return 
	end
	
	return self:LoadString(text, filepath);
end

function Independent:Load(files)
	for _, filename in ipairs(files) do
		self:LoadFile(filename);
	end
end

function Independent:XPCall(callback, ...)
	return xpcall(callback, function (err) 
		print("Independent:Call:Error", err);
		DebugStack();
	end, ...);
end

function Independent:Call(...)
	if (not self:GetCodeEnv()) then return end
	self:GetCodeEnv().__activate_event_callback__(...);
end

function Independent:CallEventCallBack(eventType)
	local CodeEnv = self:GetCodeEnv();
	if (not CodeEnv) then return print("CodeEnv Not Exist", eventType) end 
	local __event_callback__ = CodeEnv.__event_callback__[eventType];
	if (not __event_callback__) then return end
	for _, callback in pairs(__event_callback__) do
		self:Call(callback);
	end
end

function Independent:Restart()
	local __module_env_list__ = self.__module_env_list__;
	self:Reset();
	local CodeEnv = self:GetCodeEnv();
	for _, __module_env__ in ipairs(__module_env_list__) do
		__module_env__.__code_env__ = CodeEnv;
		local __reload__ = __module_env__.__module__.__reload__;
		if (type(__reload__) == "function") then 
			table.insert(self.__module_env_list__, __module_env__);
			__reload__();
		end 
	end
end

function Independent:Start(filename)
	if (self:IsRunning()) then return end
	print("====================Independent:Start=====================");
	-- 确保已初始化
	self:Init();

	-- 设置运行标识
	self:SetRunning(true);
	self:SetTickCount(0);
	self:SetMainFileName(filename);

	-- 激活上下文环境
	local CodeEnv = self:GetCodeEnv();

	-- 如果独占鼠标键盘则接管Context
	if (not self:IsShareMouseKeyBoard()) then
		CodeEnv.SceneContext:activate();
	end

	-- 开始定时器
	local loopTickCount = self:GetLoopTickCount();
	local duration = math.floor(1000 / loopTickCount);
	self:GetLoopTimer():Change(duration, duration);

	self:Call(function()
		-- 先加载内部模块
		self:LoadInnerModule();

		-- 再加载入口文件
		self:LoadFile(self:GetMainFileName());

		-- 触发 MAIN 事件回调
		self:CallEventCallBack(CodeEnv.EventType.MAIN);

		-- 调用 快捷方式 MAIN
		self:Call(rawget(CodeEnv, "main"));
	end);
end

function Independent:Tick()
	local CodeEnv = self:GetCodeEnv();
	if (not CodeEnv) then return end
	local function Tick()
		-- 虚拟时间
		self:SetTickCount(self:GetTickCount() + 1);

		-- 激活tick事件
		CodeEnv.__activate_tick_event__();
		
		-- 触发定时回调
		self:CallEventCallBack(CodeEnv.EventType.LOOP);

		-- 触发 LOOP 快捷回调
		local loop = rawget(CodeEnv, "loop");
		if (loop) then self:Call(loop) end 
	end
	local TickSpeed = self:GetTickSpeed();
	for i = 1, TickSpeed do
		Tick();
	end
end

function Independent:Stop()
	local CodeEnv = self:GetCodeEnv();
	if (not CodeEnv or not self:IsRunning()) then return end
	print("====================Independent:Stop=====================");

	self:SetRunning(false);

	-- 停止Tick
	if (self:GetLoopTimer()) then
		self:GetLoopTimer():Change();
		self:SetLoopTimer(nil);
	end

	-- 唤醒一次所有协程, 让其正常退出
	self:Tick();

	-- 调用清理函数
	self:CallEventCallBack(CodeEnv.EventType.CLEAR);
	if (type(rawget(CodeEnv, "clear")) == "function") then 
		self:Call(CodeEnv.clear);
	end

	CodeEnv.SceneContext:Inactivate();

	CodeEnv:Clear();
	self:SetCodeEnv(nil);

	-- collectgarbage("collect");
end


function Independent:OnWorldLoaded()
end

function Independent:OnWorldUnloaded()
    self:Stop();
end

Independent:InitSingleton();
