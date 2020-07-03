--[[
Title: Common
Author(s): wxa
Date: 2020/6/19
Desc: Common
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Common.lua");
local Common = commonlib.gettable("Mod.GeneralGameServerMod.Common.Common");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketTypes.lua");

local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketTypes");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");

local Common = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Common.Common"));

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
    NPL.AddPublicFile("Mod/GeneralGameServerMod/Common/Connection.lua", 401);
	-- 初始化插件配置
	Config:Init(isServer);

	-- 设置日志等级
	if (Config.IsDevEnv or Config.IsTestEnv) then
		Log:SetLevel("DEBUG");
	else 
		Log:SetLevel("INFO");
	end
end

function Common:GetConfig() 
    return Config;
end
