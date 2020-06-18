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
NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketTypes.lua");
NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameWorld.lua");

local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketTypes");
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
    PacketTypes:StaticInit();

    -- 初始化网络
    NPL.AddPublicFile("Mod/GeneralGameServerMod/Common/Connection.lua", 401);
    NPL.StartNetServer("127.0.0.1", "0");
    
    -- 监听世界加载完成事件
    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");

    self.inited = true;
    return self;
end

function GeneralGameClient:Exit()
    GameLogic:Disconnect("WorldLoaded", self, self.OnWorldLoaded, "DisconnectOne");
end

function GeneralGameClient:LoadWorld(ip, port, worldId, username, password)
    -- 初始化
    self:Init();

    local defaultWorldId = 12348;
    worldId = worldId == nil and defaultWorldId or worldId; 

    self.newIp = ip;
    self.newPort = port;
    self.newWorldId = worldId;
    self.newUsername = username;
    self.newPassword = password;

    -- 与当前世界相同则不处理
    if (self.worldId == worldId) then return end;

    -- 退出旧世界
    if (self.world) then self.world:OnExit(); end
    
    self.IsReplaceWorld = true;

    GameLogic.RunCommand(string.format("/loadworld %d", self.newWorldId));    
end

-- 世界加载
function GeneralGameClient:OnWorldLoaded() 
    -- 是否需要替换世界
    if (not self.IsReplaceWorld) then return end
    self.IsReplaceWorld = false;

    self.ip = self.newIp;
    self.port = self.newPort;
    self.worldId = self.newWorldId;
    self.username = self.newUsername;
    self.password = self.newPassword;

    -- 更新当前世界ID
    self.world = GeneralGameWorld:new():Init();
    GameLogic.ReplaceWorld(self.world);

    -- 登录世界
    self.world:Login({ip = self.ip, port = self.port, worldId = self.worldId, username = self.username, password = self.password});
end

--  正确流程: 登录成功 => 加载打开世界 => 替换世界
