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
local LoopTickCount = 20;   -- 定时器频率

function Independent:ctor()
	self:SetCodeEnv(setmetatable({}, {__index = CodeEnv:new():Init(self)}));

	self.timer = commonlib.Timer:new({callbackFunc = function()
		Independent:Tick();
	end});
end

function Independent:LoadFile(filename)
	local text = Helper.ReadFile(filename);
	if (not text or text == "") then return end
	local code_func, errormsg = loadstring(text, filename);
	if errormsg then
		return GGS.INFO("Independent:LoadFile LoadString Failed", filename, errormsg);
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

function Independent:Start()
	if (self:IsRunning()) then return end

	local CodeEnv = self:GetCodeEnv();

	if (type(rawget(CodeEnv, "main")) ~= "function") then
		GGS.INFO("Independent:Start script entry not found.");
		self:Stop();
		return ;
	end

	if (not self:Call(CodeEnv.main)) then 
		self:Stop();
		return ;
	end

	CodeEnv.SceneContext:activate();
	self.timer:Change(LoopTickCount, LoopTickCount);

	self:SetRunning(true);
end

function Independent:Tick()
	local CodeEnv = self:GetCodeEnv();

	for _, callback in pairs(CodeEnv.__timer_callback__) do
		if (not self:Call(callback)) then
			self:Stop();
		end
	end

	if (type(rawget(CodeEnv, "loop")) ~= "function") then return end
	if (not self:Call(CodeEnv.loop, CodeEnv.TickEvent:Init())) then self:Stop() end
end

function Independent:Stop()
	GameLogic.ActivateDefaultContext();

	local CodeEnv = self:GetCodeEnv();
	if (self.timer) then
		self.timer:Change();
		self.timer = nil;
	end

	if (type(rawget(CodeEnv, "clear")) == "function") then 
		self:Call(CodeEnv.clear);
	end

	CodeEnv:Clear();

	self:SetRunning(false);

	-- collectgarbage("collect");
end

Independent:InitSingleton();