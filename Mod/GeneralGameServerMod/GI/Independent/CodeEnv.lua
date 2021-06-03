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

-- 先加载相关脚本, 避免相关文件都需要Load 
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/PhysicsWorld.lua");

local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua", IsDevEnv);
local PlayerAPI = NPL.load("./API/PlayerAPI.lua", IsDevEnv);
local SystemAPI = NPL.load("./API/SystemAPI.lua", IsDevEnv);
local UIAPI = NPL.load("./API/UIAPI.lua", IsDevEnv);
local EntityAPI = NPL.load("./API/EntityAPI.lua", IsDevEnv);

local CodeEnv = commonlib.inherit(nil, NPL.export());

function CodeEnv:ctor()
	self._G = self;

	self.__modules__ = {};        -- 模块
	self.__windows__ = {};        -- 窗口
	self.__entities__ = {};       -- 实例
end


function CodeEnv:InstallAPI(api)
	for key, val in pairs(api) do   -- pairs 不会遍历元表
		self[key] = val;
	end
end

function CodeEnv:Init(Independent)
    self.Independent = Independent;
	self.dcall = Independent.call

	PlayerAPI(self);
	SystemAPI(self);
	UIAPI(self);
	EntityAPI(self);
	
    return self;
end

function CodeEnv:Clear()
	-- 关闭相关窗口
	for _, window in pairs(self.__windows__) do
		window:CloseWindow();
	end
end
