--[[
Title: Common
Author(s): wxa
Date: 2020/6/19
Desc: Common
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Common.lua");
local Common = commonlib.gettable("Mod.GeneralGameServerMod.Common.Common");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketTypes.lua");

local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");

local Common = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Common"));

function Common:Init(isServer)
    if (self.inited) then return end
	self.inited = true;

	-- 设置随机种子
	math.randomseed(ParaGlobal.timeGetTime());
	
    -- 设置日志默认模块名
    Log:SetDefaultModuleName("GeneralGameServerMod");
	-- 初始化网络包
	PacketTypes:StaticInit();
	-- 初始化网络连接
	Connections:Init();
	-- 暴露接口文件
    NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Common/Connection.lua", 401);
	-- 初始化插件配置
	Config:Init(isServer);

	-- 设置日志等级
	if (Config.IsDevEnv or Config.IsTestEnv) then
		Log:SetLevel("DEBUG");
	else 
		Log:SetLevel(self.Log.level or "INFO");
		-- 正式环境禁用网络包日志
		Log:SetModuleLogEnable("Mod.GeneralGameServerMod.Core.Common.Connection", false);
        Log:SetModuleLogEnable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer", false);
	end
end

function Common:GetConfig() 
    return Config;
end
