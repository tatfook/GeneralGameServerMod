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
local lfs = commonlib.Files.GetLuaFileSystem();

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local SceneContext = NPL.load("./SceneContext.lua");

local API = NPL.load("./API/API.lua", IsDevEnv);
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
local RPCAPI = NPL.load("./API/RPCAPI.lua", IsDevEnv);
local FileAPI = NPL.load("./API/FileAPI.lua", IsDevEnv);

local CodeEnv = commonlib.inherit(nil, NPL.export());

CodeEnv.lfs = lfs;
CodeEnv.ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
CodeEnv.vector3d = commonlib.gettable("mathlib.vector3d");
CodeEnv.IsDevEnv = IsDevEnv;
CodeEnv.Debug = GGS.Debug;
CodeEnv.DebugStack = DebugStack;

CodeEnv.EventEmitter = EventEmitter;
CodeEnv.SceneContext = SceneContext;

function CodeEnv:ctor()
	self._G = self;
	self.__env__ = self;          -- 快捷方式

	self.__modules__ = {};        -- 模块
	self.__tables__ = {};         -- 全局表集
	self.__windows__ = {};        -- 窗口
	self.__entities__ = {};       -- 实例
	self.__event_callback__ = {}; -- 事件回调
	self.__coroutines__ = {};     -- 协程资源集
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
	self.__get_coroutine_data__ = function(__co__)
		if (self.__is_touch_device__()) then return {__windows__ = {}, __entities__ = {}, __event_callback__ = {}, __clean_callback__ = {}} end 

		__co__ = __co__ or self.__coroutine_running__();

		local __data__ = self.__coroutines__[__co__] or {};
		self.__coroutines__[__co__] = __data__;
		__data__.__windows__ = __data__.__windows__ or {};
		__data__.__entities__ = __data__.__entities__ or {};
		__data__.__event_callback__ = __data__.__event_callback__ or {};
		__data__.__clean_callback__ = __data__.__clean_callback__ or {};
		return __data__;
	end

	self.__add_clean_coroutine_data_callback__ = function(callback)
		if (self.__is_touch_device__()) then return end 
		
		if (type(callback) ~= "function") then return end
		self.__clean_callback__[callback] = callback;
	end

	self.__remove_clean_coroutine_data_callback__ = function(callback)
		if (self.__is_touch_device__()) then return end 
		
		if (type(callback) ~= "function") then return end
		self.__clean_callback__[callback] = nil;
	end

	self.__clean_coroutine_data__ = function(__co__)
		if (self.__is_touch_device__()) then return end 

		self.TriggerEventCallBack("__clean_coroutine_data__");

		local __data__ = self.__get_coroutine_data__(__co__);
		for key, window in pairs(__data__.__windows__) do 
			window:CloseWindow();
			self.__windows__[key] = nil; 
		end
		for key, entity in pairs(__data__.__entities__) do 
			entity:Destroy();
			self.__entities__[key] = nil;
		end 
		for event_type, callbacks in pairs(__data__.__event_callback__) do
			for callback in pairs(callbacks) do
				if (self.__event_callback__[event_type] and self.__event_callback__[event_type][callback]) then 
					self.__event_callback__[event_type][callback] = nil
				end
			end
		end 
		for _, clean_callback in pairs(__data__.__clean_callback__) do
			if (type(clean_callback) == "function") then
				clean_callback();
			end
		end
	end

	self.__is_touch_device__ = function() return System.os.IsTouchMode() end 
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
	self.__safe_callback__ = function(callback) 
		return function(...) 
			Independent:Call(callback, ...) 
		end 
	end 
	self.__loadstring__ = function(...) return Independent:LoadString(...) end
	self.__get_loop_tick_count__ = function() return Independent:GetLoopTickCount() end 
	self.__is_share_mouse_keyboard_event__ = function() return Independent:IsShareMouseKeyBoard() end 
	self.__get_tick_count__ = function() return Independent:GetTickCount() end  
	self.__get_timestamp__ = function() return math.floor(Independent:GetTickCount() * 1000 / Independent:GetLoopTickCount()) end   -- ms
	self.__set_alias_path__ = function(alias, path) Independent.__alias_path_map__[alias] = path end 
end

function CodeEnv:InstallCodeBlockAPI()
	self.__get_code_globals__ = function() return GameLogic.GetCodeGlobal() end 
end

function CodeEnv:Init(Independent)
	self:InstallLuaAPI();
	self:InstallIndependentAPI(Independent);
	self:InstallCodeBlockAPI();
	
	API(self);
	SystemAPI(self);
	EventAPI(self);
	SceneAPI(self);
	PlayerAPI(self);
	UIAPI(self);
	EntityAPI(self);
	BlockAPI(self);
	UtilityAPI(self);
	GGSAPI(self);
	NetAPI(self);
	RPCAPI(self);
	FileAPI(self);
	
    return self;
end

function CodeEnv:Clear()
	-- 关闭相关窗口
	for _, window in pairs(self.__windows__) do
		window:CloseWindow();
	end

	-- 安全移除Entity
	for _, entity in ipairs(self.__GetEntityList__()) do
		entity:Destroy();
	end
end
