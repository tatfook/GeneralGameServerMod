--[[
Title: GeneralGameClient
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界客户端
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameClient.lua");
local GeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameClient");
local client = GeneralGameClient.GetSingleton();
client.LoadWorld("127.0.0.1", "9000", 12348);
------------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Common/Packets.lua");
NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameWorld.lua");

local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameWorld");
local GeneralGameClient = commonlib.inherit(nil,commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameClient"));

function GeneralGameClient:ctor() 
    self.inited = false;
end

-- 单列模式
local g_instance;
function GeneralGameClient.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = GeneralGameClient:new();
		return g_instance;
	end
end

function GeneralGameClient:Init() 
    if (self.inited) then return self end;

    NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
    local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
	Connections:Init();

    -- 初始化网络包
    Packets:StaticInit();

    -- 初始化网络
    NPL.AddPublicFile("Mod/GeneralGameServerMod/Common/Connection.lua", 201);
    NPL.StartNetServer("127.0.0.1", "0");
	
    self.inited = true;
    return self;
end

function GeneralGameClient:LoadWorld(ip, port, worldId)
    -- 初始化
    self:Init();

    -- 创建世界
    if (self.world) then 
        self.world:OnExit();
    end
    self.world = GeneralGameWorld:new():Init();

    -- 登录世界
    self.world:Login({ip = ip, port = port, worldId = worldId});
end
