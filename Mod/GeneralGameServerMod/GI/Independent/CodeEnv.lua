--[[
Title: CodeEnv
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local CodeEnv = NPL.load("Mod/GeneralGameServerMod/GI/Independent/CodeEnv.lua");
------------------------------------------------------------
]]

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Vue = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Vue.lua", IsDevEnv);
local EventEmitter = NPL.load("../Game/Event/EventEmitter.lua", IsDevEnv);
local Event = NPL.load("../Game/Event/Event.lua", IsDevEnv);
local TickEvent = NPL.load("../Game/Event/TickEvent.lua", IsDevEnv);
local SceneContext = NPL.load("../Game/Event/SceneContext.lua", IsDevEnv);

local SceneAPI = NPL.load("./API/SceneAPI.lua", IsDevEnv);
local PlayerAPI = NPL.load("./API/PlayerAPI.lua", IsDevEnv);
local SystemAPI = NPL.load("./API/SystemAPI.lua", IsDevEnv);
local EventAPI = NPL.load("./API/EventAPI.lua", IsDevEnv);
local UIAPI = NPL.load("./API/UIAPI.lua", IsDevEnv);
local EntityAPI = NPL.load("./API/EntityAPI.lua", IsDevEnv);
local BlockAPI = NPL.load("./API/BlockAPI.lua", IsDevEnv);
local UtilityAPI = NPL.load("./API/UtilityAPI.lua", IsDevEnv);
local GGSAPI = NPL.load("./API/GGSAPI.lua", IsDevEnv);
local NetAPI = NPL.load("./API/NetAPI.lua", IsDevEnv);

local CodeEnv = commonlib.inherit(nil, NPL.export());

CodeEnv.IsDevEnv = IsDevEnv;
CodeEnv.Vue = Vue;
CodeEnv.Debug = GGS.Debug;
CodeEnv.DebugStack = DebugStack;

CodeEnv.EventEmitter = EventEmitter;
CodeEnv.SceneContext = SceneContext;
CodeEnv.Event = Event;
CodeEnv.TickEvent = TickEvent;
CodeEnv.Unpack = CommonLib.Table.Unpack;
CodeEnv.Pack = CommonLib.Table.Pack;

function CodeEnv:ctor()
	self._G = self;
	self.__env__ = self;          -- 快捷方式

	self.___modules___ = {};      -- 防止文件代码重复执行
	self.__modules__ = {};        -- 模块
	self.__windows__ = {};        -- 窗口
	self.__entities__ = {};       -- 实例
	self.__event_callback__ = {}; -- 事件回调
end

function CodeEnv:InstallAPI(api)
	for key, val in pairs(api) do   -- pairs 不会遍历元表
		self[key] = val;
	end
end

function CodeEnv:InstallLuaAPI()
	self.__select__ = select;
	self.__coroutine_create__ = coroutine.create;
	self.__coroutine_wrap__ = coroutine.wrap;
	self.__coroutine_running__ = coroutine.running;
	self.__coroutine_resume__ = coroutine.resume;
	self.__coroutine_yield__ = coroutine.yield;
	self.__coroutine_status__ = coroutine.status;
end

function CodeEnv:InstallIndependentAPI(Independent)
	-- 内部函数, 不可随意调用
	self.__co__ = Independent.__co__;
	self.__yield__ = function(...) Independent:Yield(...) end
	self.__clear__ = function() self:Clear() end 
	self.__restart__ = function() Independent:Restart() end
	self.__start__ = function(...) Independent:Start(...) end
	self.__stop__ = function() Independent:Stop() end
	self.__call__ = function(...) return Independent:Call(...) end
	self.__loadfile__ = function(...) return Independent:LoadFile(...) end
	self.__is_running__ = function() return Independent:IsRunning() end 
end

function CodeEnv:InstallCodeBlockAPI()
	self.__get_code_globals__ = function() return GameLogic.GetCodeGlobal() end 
end

function CodeEnv:Init(Independent)
	self:InstallLuaAPI();
	self:InstallIndependentAPI(Independent);
	self:InstallCodeBlockAPI();
	
	SceneAPI(self);
	PlayerAPI(self);
	SystemAPI(self);
	EventAPI(self);
	UIAPI(self);
	EntityAPI(self);
	BlockAPI(self);
	UtilityAPI(self);
	GGSAPI(self);
	NetAPI(self);
	
    return self;
end

function CodeEnv:Clear()
	-- 关闭相关窗口
	for _, window in pairs(self.__windows__) do
		window:CloseWindow();
	end

	-- 移除 Entity
	for _, entity in pairs(self.__entities__) do
		entity:SetDead();
	end
end
