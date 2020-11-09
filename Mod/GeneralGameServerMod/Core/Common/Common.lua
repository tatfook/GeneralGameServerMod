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
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketTypes.lua");

local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");

local Common = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Common"));

function Common:Init(isServer)
    if (self.inited) then return end
	self.inited = true;

	-- 设置随机种子
	math.randomseed(ParaGlobal.timeGetTime());
	
	-- 初始化网络包
	PacketTypes:StaticInit();

	-- 初始化网络连接
	Connections:Init();
	
	-- 暴露接口文件
    NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Common/Connection.lua", 401);
end
