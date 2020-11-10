--[[
Title: ThreadHelper
Author(s): wxa
Date: 2020/6/10
Desc: 线程辅助类
use the lib: 
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/ThreadHelper.lua");
local ThreadHelper = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.ThreadHelper");
-------------------------------------------------------
]]

local GGS = NPL.load("../Common/GGS.lua", IsDevEnv);

-- NPL.load("script/ide/System/System.lua");
-- NPL.load("script/apps/Aries/Creator/Game/Network/Connections.lua");
-- NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketTypes.lua");
-- NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");

-- local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
-- local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
-- local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");

local ThreadHelper = NPL.export();

function ThreadHelper:Init()
    -- 配置初始化
    -- Config:StaticInit();

    -- 初始化网络包
	-- PacketTypes:StaticInit();

	-- 初始化网络连接
	-- Connections:Init();
    
    -- GGS.INFO.Format("========================Thread(%s) Init======================", __rts__:GetName());
    print(string.format("========================Thread(%s) Init======================", __rts__:GetName()));
end

-- 激活函数
local function activate()
	local action = msg and msg.action;

    if (action == "Init") then 
        return ThreadHelper:Init();
    end
end

NPL.this(activate);