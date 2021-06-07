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

local Event = NPL.load("../Game/Input/Event.lua", IsDevEnv);
local TickEvent = NPL.load("../Game/Input/TickEvent.lua", IsDevEnv);
local SceneContext = NPL.load("../Game/Input/SceneContext.lua", IsDevEnv);

local SceneAPI = NPL.load("./API/SceneAPI.lua", IsDevEnv);
local PlayerAPI = NPL.load("./API/PlayerAPI.lua", IsDevEnv);
local SystemAPI = NPL.load("./API/SystemAPI.lua", IsDevEnv);
local EventAPI = NPL.load("./API/EventAPI.lua", IsDevEnv);
local UIAPI = NPL.load("./API/UIAPI.lua", IsDevEnv);
local EntityAPI = NPL.load("./API/EntityAPI.lua", IsDevEnv);
local BlockAPI = NPL.load("./API/BlockAPI.lua", IsDevEnv);
local UtilityAPI = NPL.load("./API/UtilityAPI.lua", IsDevEnv);

local CodeEnv = commonlib.inherit(nil, NPL.export());

CodeEnv.SceneContext = SceneContext;
CodeEnv.Event = Event;
CodeEnv.TickEvent = TickEvent;

function CodeEnv:ctor()
	self._G = self;

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

function CodeEnv:Init(Independent)
    self.Independent = Independent;
	self.dcall = Independent.Call

	SceneAPI(self);
	PlayerAPI(self);
	SystemAPI(self);
	EventAPI(self);
	UIAPI(self);
	EntityAPI(self);
	BlockAPI(self);
	UtilityAPI(self);

    return self;
end

function CodeEnv:Clear()
	-- 关闭相关窗口
	for _, window in pairs(self.__windows__) do
		window:CloseWindow();
	end
end
