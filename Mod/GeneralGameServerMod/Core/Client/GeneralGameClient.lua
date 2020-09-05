--[[
Title: GeneralGameClient
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界客户端
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameClient.lua");
local GeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameClient");
GeneralGameClient:LoadWorld({ip = "127.0.0.1", port = "9000", worldId = "12348"});
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/Entity.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameWorld.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Common.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/NetClientHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityMainPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityOtherPlayer.lua");
local Entity = commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity");
local NetClientHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.NetClientHandler");
local EntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer");
local EntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityOtherPlayer");
local Common = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Common");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local GeneralGameClient = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameClient"));
local AssetsWhiteList = NPL.load("Mod/GeneralGameServerMod/Core/Client/AssetsWhiteList.lua"); 

GeneralGameClient:Property("World", nil);  -- 当前世界

-- 类共享变量 强制同步块列表
GeneralGameClient.syncForceBlockList = commonlib.UnorderedArraySet:new();
GeneralGameClient.options = {
    isSyncBlock = if_else(Config.IsDevEnv, true, false),
    isSyncForceBlock = true,
    isSyncCmd = true,
    areaSize = 0,   -- 表示不做限制
}

function GeneralGameClient:ctor() 
    self.inited = false;
    self.netCmdList = commonlib.UnorderedArraySet:new();  -- 网络命令列表, 禁止命令重复运行 
end

function GeneralGameClient:Init() 
    if (self.inited) then return self end;
    
    Common:Init(false);

    -- 设置实体ID起始值
    Entity:SetEntityId(Config.maxEntityId);

    -- 禁用服务器 指定为客户端
    NPL.StartNetServer("127.0.0.1", "0");

    -- 监听世界加载完成事件
    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");

    -- 禁用点击继续
    GameLogic.options:SetClickToContinue(false);

    self.inited = true;
    return self;
end

function GeneralGameClient:Exit()
    GameLogic:Disconnect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic:Disconnect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
    self:OnWorldUnloaded();
end

-- 获取玩家支持的形象列表
function GeneralGameClient:GetAssetsWhiteList()
    return AssetsWhiteList;
end

-- 获取世界类
function GeneralGameClient:GetGeneralGameWorldClass()
    return GeneralGameWorld;
end
-- 获取网络处理类
function GeneralGameClient:GetNetClientHandlerClass()
    return NetClientHandler;
end
-- 获取主玩家类
function GeneralGameClient:GetEntityMainPlayerClass()
    return EntityMainPlayer;
end
-- 获取其它玩家类
function GeneralGameClient:GetEntityOtherPlayerClass()
    return EntityOtherPlayer;
end
-- 获取配置
function GeneralGameClient:GetConfig()
    return Config;
end
-- 获取强制同步块列表
function GeneralGameClient:GetSyncForceBlockList() 
    return self.syncForceBlockList;
end
-- 获取块管理器
function GeneralGameClient:GetBlockManager()
    return self:GetWorld():GetBlockManager();
end
-- 获取客户端选项
function GeneralGameClient:GetOptions() 
    return self.options;
end
-- 设置客户端选项
function GeneralGameClient:SetOptions(opts)
    commonlib.partialcopy(self.options, opts);
    return self.options;
end

-- 是否同步强制块
function GeneralGameClient:IsSyncForceBlock()
    return self:GetOptions().isSyncForceBlock;
end

-- 是否同步方块
function GeneralGameClient:IsSyncBlock()
    return if_else(Config.IsDevEnv, true, self:GetOptions().isSyncBlock);
end

-- 是否同步命令
function GeneralGameClient:IsSyncCmd()
    return self:GetOptions().isSyncCmd;
end

-- 获取视图大小
function GeneralGameClient:GetAreaSize()
    return tonumber(self:GetOptions().areaSize) or 0;
end

-- 是否获取可用服务器列表
function GeneralGameClient:IsShowWorldList()
    return if_else(Config.IsDevEnv, true, false);
end

-- 加载世界
function GeneralGameClient:LoadWorld(opts)
    -- 初始化
    self:Init();
    
    -- 覆盖默认选项
    local options = self:SetOptions(opts);
    -- 设定世界ID 优先取当前世界ID  其次用默认世界ID
    local curWorldId = GameLogic.options:GetProjectId();

    -- 确定世界ID
    options.worldId = tostring(opts.worldId or curWorldId or Config.defaultWorldId);
    options.username = options.username or self:GetUserInfo().username;

    -- 打印选项值
    Log:Info(options);

    -- only reload world if world id does not match
    local isReloadWorld = tostring(options.worldId) ~= tostring(curWorldId); 

    -- 退出旧世界
    if (self:GetWorld()) then 
        -- 相同世界且已登录直接跳出
        if (not IsDevEnv and self:GetWorld():IsLogin() and self:GetWorld():GetWorldId() == options.worldId) then return end
        -- 退出旧世界
        self:GetWorld():OnExit(); 
    end

    -- 标识替换, 其它方式loadworld不替换
    self.IsReplaceWorld = true;

    -- 以只读方式重新进入
    if (isReloadWorld) then
        GameLogic.RunCommand(string.format("/loadworld %s", options.worldId));    
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
    local GeneralGameWorldClass = self:GetGeneralGameWorldClass() or GeneralGameWorld;
    self:SetWorld(GeneralGameWorldClass:new():Init(self));
    GameLogic.ReplaceWorld(self:GetWorld());

    -- 登录世界
    local options = self:GetOptions();
    if (options.ip and options.port) then
        self:GetWorld():Login(options);
    else
        self:ConnectControlServer(options); -- 连接控制器服务, 获取世界服务
    end
end

-- 世界退出
function GeneralGameClient:OnWorldUnloaded()
    if (self:GetWorld()) then
        self:GetWorld():OnExit();
    end
    self:SetWorld(nil);
end

-- 获取世界网络处理程序
function GeneralGameClient:GetWorldNetHandler() 
    return self:GetWorld() and self:GetWorld():GetNetHandler();
end

-- 执行网络命令
function GeneralGameClient:RunNetCommand(cmd, opts)
    local netHandler = self:GetWorld() and self:GetWorld():GetNetHandler();
    if (not netHandler or not self:IsSyncCmd()) then return end;
    -- 命令存在且执行到发包说明命令执行完成, 在收到网络包时加入
    if (self:GetNetCmdList():contains(cmd)) then
        Log:Debug("end exec net cmd: " .. cmd);
        self:GetNetCmdList():removeByValue(cmd);
        return;
    end

    Log:Debug("send net cmd: " .. cmd);
    netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({
        action = "SyncCmd",
        data = {
            cmd = cmd,
            opts = opts,
        },
    }));
end

-- 处理鼠标事件
function GeneralGameClient:handleMouseEvent(event)
    if (not self:GetWorld()) then return end;
    self:GetWorld():handleMouseEvent(event);
end

-- 连接控制服务器
function GeneralGameClient:ConnectControlServer()
    local options = self:GetOptions();
    local config = self:GetConfig();
    local serverIp, serverPort = options.serverIp or config.serverIp, options.serverPort or config.serverPort;

    Log:Debug("contrl server ServerIp: %s, ServerPort: %s", Config.serverIp, Config.serverPort);

    self.controlServerConnection = Connection:new():InitByIpPort(Config.serverIp, Config.serverPort, self);
    self.controlServerConnection:SetDefaultNeuronFile("Mod/GeneralGameServerMod/Core/Server/ControlServer.lua");
    self.controlServerConnection:Connect(5, function(success)
        if (not success) then
            _guihelper.MessageBox(L"无法链接到这个服务器,可能该服务器未开启或已关闭.详情请联系该服务器管理员.");
            return Log:Info("无法连接控制器服务器");
        end

        self:SelectServerAndWorld();
    end);
end

-- 选择服务器和世界
function GeneralGameClient:SelectServerAndWorld()
    if (self:IsShowWorldList()) then
        self.controlServerConnection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({
            action = "ServerWorldList"
        }));
    else
    end
    local options = self:GetOptions();
    self.controlServerConnection:AddPacketToSendQueue(Packets.PacketWorldServer:new():Init({
        worldId = options.worldId,
        worldName = options.worldName,
    }));
end

-- 处理通用数据包
function GeneralGameClient:handleGeneral(packetGeneral)
    if (packetGeneral.action == "ServerWorldList") then
        self:handleServerWorldList(packetGeneral);
    end
end

-- 处理服务器推送过来的统计信息
function GeneralGameClient:handleServerWorldList(packetGeneral)
end

-- 发送获取世界服务器
function GeneralGameClient:handleWorldServer(packetWorldServer)
    local options = self:GetOptions();
    options.ip = packetWorldServer.ip;
    options.port = packetWorldServer.port;
    if (not options.ip or not options.port) then
        Log:Info("服务器繁忙, 暂无合适的世界服务器提供");
        return;
    end

    -- 登录世界
    self:GetWorld():Login(options);

    -- 关闭控制服务器的链接
    self.controlServerConnection:CloseConnection();
end


-- 获取当前认证用户信息
function GeneralGameClient:GetUserInfo()
    -- return {};
end

-- 获取当前系统世界信息
function GeneralGameClient:GetWorldInfo()
    -- return {};
end

-- 是否是匿名用户
function GeneralGameClient:IsAnonymousUser()
    return true;
end

-- 获取网络命令
function GeneralGameClient:GetNetCmdList()
    return self.netCmdList;
end

-- 调试
function GeneralGameClient:Debug(action)
    action = string.lower(action or "");
    if (action == "client" or action == "") then
        return self:ShowDebugInfo(self:GetOptions());
    end

    local netHandler = self:GetWorldNetHandler();
    if (not netHandler) then return end
    if (action == "worldinfo") then
        netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "WorldInfo"}}));
    elseif (action == "serverinfo") then
        netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "ServerInfo"}}));
    end
end

-- 显示调试信息
function GeneralGameClient:ShowDebugInfo(debug)
    Log:Info(commonlib.Json.Encode(debug));
    _guihelper.MessageBox(commonlib.serialize(debug));
end


-- 初始化成单列模式
GeneralGameClient:InitSingleton();
