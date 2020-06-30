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

NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameWorld.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Common.lua");
local Common = commonlib.gettable("Mod.GeneralGameServerMod.Common.Common");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameWorld");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
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
    
    Common:Init(false);

    -- 禁用服务器 指定为客户端
    NPL.StartNetServer("127.0.0.1", "0");

    -- 监听世界加载完成事件
    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");

    -- 禁用点击继续
    GameLogic.options:SetClickToContinue(false);

    self.inited = true;
    return self;
end

function GeneralGameClient:Exit()
    GameLogic:Disconnect("WorldLoaded", self, self.OnWorldLoaded, "DisconnectOne");
end

function GeneralGameClient:LoadWorld(options)
    -- 初始化
    self:Init();
    -- 保存选项
    self.options = options;
    
    -- 设定世界ID 优先取当前世界ID  其次用默认世界ID
    local curWorldId = GameLogic.options:GetProjectId();

    -- 确定世界ID
    options.worldId = options.worldId or curWorldId or Config.defaultWorldId;
    
    -- only reload world if world id does not match
    local isReloadWorld = options.worldId ~= curWorldId; 

    -- 退出旧世界
    if (self.world) then self.world:OnExit(); end

    -- 标识替换, 其它方式loadworld不替换
    self.IsReplaceWorld = true;

    -- 以只读方式重新进入
    if (isReloadWorld) then
        GameLogic.RunCommand(string.format("/loadworld %d", self.worldId));    
    else
        self:OnWorldLoaded();
    end
end

-- 世界加载
function GeneralGameClient:OnWorldLoaded() 
    -- 是否需要替换世界
    if (not self.IsReplaceWorld) then return end
    self.IsReplaceWorld = false;

    -- 更新当前世界ID
    self.world = GeneralGameWorld:new():Init(self.options.worldId);
    GameLogic.ReplaceWorld(self.world);

    -- 登录世界
    if (self.options.ip and self.options.port) then
        self.world:Login(self.options);
    else
        self:ConnectControlServer(self.options); -- 连接控制器服务, 获取世界服务
    end
end
--  正确流程: 登录成功 => 加载打开世界 => 替换世界


-- 连接控制服务器
function GeneralGameClient:ConnectControlServer(options)
    Log:Debug("ServerIp: %s, ServerPort: %s", Config.serverIp, Config.serverPort);
    self.controlServerConnection = Connection:new():InitByIpPort(Config.serverIp, Config.serverPort, self);
    self.controlServerConnection:SetDefaultNeuronFile("Mod/GeneralGameServerMod/Server/ControlServer.lua");
    self.controlServerConnection:Connect(5, function(success)
        if (not success) then
            return Log:Info("无法连接控制器服务器");
        end

        self.controlServerConnection:AddPacketToSendQueue(Packets.PacketWorldServer:new():Init({
            worldId = worldId,
            parallelWorldName = options.parallelWorldName,
        }));
    end);
end

-- 发送获取世界服务器
function GeneralGameClient:handleWorldServer(packetWorldServer)
    local options = self.options;
    options.ip = packetWorldServer.ip;
    options.port = packetWorldServer.port;
    if (not options.ip or not options.port) then
        Log:Info("服务器繁忙, 暂无合适的世界服务器提供");
        return;
    end

    -- 登录世界
    self.world:Login(options);

    -- 关闭控制服务器的链接
    self.controlServerConnection:CloseConnection();
end
