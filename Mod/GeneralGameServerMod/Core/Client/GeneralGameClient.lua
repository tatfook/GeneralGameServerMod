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
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMain.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameWorld.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/ClientDataHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/NetClientHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityMainPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityOtherPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/AssetsWhiteList.lua");
local AssetsWhiteList = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.AssetsWhiteList");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local ParaWorldMain = commonlib.gettable("Paracraft.Controls.ParaWorldMain");
local Entity = commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity");
local NetClientHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.NetClientHandler");
local EntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer");
local EntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityOtherPlayer");
local ClientDataHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.ClientDataHandler");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local GeneralGameClient = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameClient"));

local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

GeneralGameClient:Property("World", nil);                  -- 当前世界
GeneralGameClient:Property("MainPlayerEntityScale", nil);  -- 玩家实体大小
GeneralGameClient:Property("MainPlayerEntityAsset", nil);  -- 玩家实体模型
GeneralGameClient:Property("MainPlayerEntitySkin", nil);   -- 玩家实体模型皮肤
GeneralGameClient:Property("ConnectionCallBack", nil);     -- 连接成功回调
GeneralGameClient:Property("DisconnectionCallBack", nil);  -- 断开连接成功回调
GeneralGameClient:Property("SyncEntityInfo", true, "IsSyncEntityInfo");                 -- 是否同步实体信息
GeneralGameClient:Property("EnableAssetsWhiteList", true, "IsEnableAssetsWhiteList");   -- 是否启用样式白名单

-- 类共享变量 强制同步块列表
GeneralGameClient.syncForceBlockList = commonlib.UnorderedArraySet:new();
GeneralGameClient.options = {
    isSyncBlock = if_else(GGS.IsDevEnv, true, false),
    isSyncForceBlock = true,
    isSyncCmd = true,
    areaSize = 0,   -- 表示不做限制

    -- config
    defaultWorldId = 10373,
    serverIp = IsDevEnv and "127.0.0.1" or "ggs.keepwork.com";
    serverPort = "9000";
}

function GeneralGameClient:ctor() 
    self.inited = false;
    self.userinfo = {};
    self.netCmdList = commonlib.UnorderedArraySet:new();  -- 网络命令列表, 禁止命令重复运行 
end

function GeneralGameClient:InitNetSetting()
    local attr = NPL.GetAttributeObject();
    NPL.SetUseCompression(true, true);
	attr:SetField("CompressionLevel", -1);
	attr:SetField("CompressionThreshold", 1024 * 2);
	
    -- 暴露接口文件
    NPL.AddPublicFile("Mod/GeneralGameServerMod/Core/Common/Connection.lua", 401);
end

function GeneralGameClient:Init() 
    if (self.inited) then return self end;
    
    -- 初始化网络配置
    self:InitNetSetting();

    -- 设置随机种子
	math.randomseed(ParaGlobal.timeGetTime());
    
    -- 设置实体ID起始值
    Entity:SetEntityId(GGS.MaxEntityId);

    -- 禁用服务器 指定为客户端
    NPL.StartNetServer("127.0.0.1", "0");

    -- 监听世界加载完成事件
    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");

    -- 禁用点击继续
    GameLogic.options:SetClickToContinue(false);

    -- 客户端日志禁用
    GGS.NetDebug.Disable();

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
-- 获取网络数据处理类
function GeneralGameClient:GetClientDataHandlerClass()
    return ClientDataHandler;
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
    if (self.options.editable) then
        self.options.editable = not GameLogic.IsReadOnly();
    end
    return self.options;
end

-- 是否是并行世界
function GeneralGameClient:IsParaWorld()
    return self:GetOptions().isParaWorld;
end

-- 是否同步强制块
function GeneralGameClient:IsSyncForceBlock()
    return self:GetOptions().isSyncForceBlock;
end

-- 是否同步方块
function GeneralGameClient:IsSyncBlock()
    return if_else(GGS.IsDevEnv, true, self:GetOptions().isSyncBlock);
end

-- 是否同步命令
function GeneralGameClient:IsSyncCmd()
    return self:GetOptions().isSyncCmd;
end

-- 获取视图大小
function GeneralGameClient:GetAreaSize()
    return tonumber(self:GetOptions().areaSize) or 0;
end

-- 是否可以飞行
function GeneralGameClient:IsCanFly()
    return true;
end

-- 获取当前世界类型
function GeneralGameClient:GetWorldType()
    if (ParaWorldMain:IsMiniWorld()) then
        return "ParaWordMini";   -- 家园
    elseif (ParaWorldMain:IsCurrentParaWorld()) then
        return "ParaWorld";      -- 平行世界
    else
        return "World";
    end
end

-- 替换世界
function GeneralGameClient:ReplaceWorld(opts)
    -- 默认加载替换世界方式 
    GameLogic.RunCommand(string.format("/loadworld %s", opts.worldId)); 
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
    options.worldId = tostring(opts.worldId or curWorldId or options.defaultWorldId);
    options.worldName = opts.worldName;
    options.worldKey = opts.worldKey;
    options.username = options.username or self:GetUserInfo().username;
    options.ip = opts.ip;            -- ip port 每次重写
    options.port = opts.port;        -- 以便动态获取
  
    -- 打印选项值
    GGS.INFO(options, opts);

    -- only reload world if world id does not match
    local isReloadWorld = tostring(options.worldId) ~= tostring(curWorldId); 

    -- 退出旧世界
    if (self:GetWorld()) then 
        -- 相同世界且已登录直接跳出
        if (not IsDevEnv and self:GetWorld():IsLogin() and self:GetWorld():GetWorldId() == options.worldId) then return end
        -- 退出旧世界
        self:GetWorld():OnExit(); 
    end

    -- 是否加载世界
    self.IsWorldLoaded = true;

    -- 以只读方式重新进入
    if (isReloadWorld) then
        self:ReplaceWorld(opts);
    else
        -- 当前世界已是所需世界, 直接执行世界加载完成逻辑
        self:OnWorldLoaded();
    end
end

-- 世界加载
function GeneralGameClient:OnWorldLoaded() 
    -- 是否需要替换世界
    if (not self.IsWorldLoaded) then return end
    self.IsWorldLoaded = false;

    -- 更新当前世界ID
    local GeneralGameWorldClass = self:GetGeneralGameWorldClass() or GeneralGameWorld;
    self:SetWorld(GeneralGameWorldClass:new():Init(self));
    GameLogic.ReplaceWorld(self:GetWorld());
    GameLogic.options:SetCanJumpInAir(self:IsCanFly());  -- 设置是否可以飞行
    -- 登录世界
    local options = self:GetOptions();
    -- 设置世界类型
    options.worldType = self:GetWorldType();  
    -- if (IsDevEnv) then options.worldType = "ParaWorld" end

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
    self.IsWorldLoaded = false;
end

-- 用户是否登录
function GeneralGameClient:IsLogin()
    return self:GetWorld() and self:GetWorld():IsLogin();
end

-- 获取世界网络处理程序
function GeneralGameClient:GetWorldNetHandler() 
    return self:GetWorld() and self:GetWorld():GetNetHandler();
end

--获取客户单数据处理程序
function GeneralGameClient:GetClientDataHandler()
    local world = self:GetWorld();
    local netHandler = world and world:GetNetHandler();
    return netHandler and netHandler:GetDataHandler();
end

-- 执行网络命令
function GeneralGameClient:RunNetCommand(cmd, opts)
    local netHandler = self:GetWorld() and self:GetWorld():GetNetHandler();
    if (not netHandler or not self:IsSyncCmd()) then return end;
    -- 命令存在且执行到发包说明命令执行完成, 在收到网络包时加入
    if (self:GetNetCmdList():contains(cmd)) then
        GGS.DEBUG("end exec net cmd: " .. cmd);
        self:GetNetCmdList():removeByValue(cmd);
        return;
    end

    GGS.DEBUG("send net cmd: " .. cmd);
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
    local serverIp, serverPort = options.serverIp, options.serverPort;

    GGS.DEBUG(string.format("control server ServerIp: %s, ServerPort: %s", serverIp, serverPort));

    self.controlServerConnection = Connection:new():Init({ip = serverIp, port = serverPort, netHandler = self});
    self.controlServerConnection:SetDefaultNeuronFile("Mod/GeneralGameServerMod/Core/Server/ControlServer.lua");
    self.controlServerConnection:Connect(5, function(success)
        if (not success) then
            -- _guihelper.MessageBox(L"无法链接到这个服务器,可能该服务器未开启或已关闭.详情请联系该服务器管理员.");
            return GGS.INFO("GGS Connect Failed: 无法连接控制器服务器");
        end

        self:SelectServerAndWorld();
    end);
end

-- 选择服务器和世界
function GeneralGameClient:SelectServerAndWorld()
    if (IsDevEnv) then 
        -- self.controlServerConnection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "ServerInfo", data = {}}));
        self.controlServerConnection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "ServerList"}));
        self.controlServerConnection:AddPacketToSendQueue(Packets.PacketGeneral:new():Init({action = "StatisticsInfo"}));
    else
    end
    local options = self:GetOptions();
    self.controlServerConnection:AddPacketToSendQueue(Packets.PacketWorldServer:new():Init({
        worldId = options.worldId,
        worldName = options.worldName,
        worldKey = options.worldKey,
    }));
end

-- 处理通用数据包
function GeneralGameClient:handleGeneral(packetGeneral)
    if (packetGeneral.action == "ServerList") then
        -- self:handleServerList(packetGeneral);
    end
end

-- 处理服务器推送过来的统计信息
function GeneralGameClient:handleServerList(packetGeneral)
    GGS.INFO(packetGeneral)
end

-- 发送获取世界服务器
function GeneralGameClient:handleWorldServer(packetWorldServer)
    local options = self:GetOptions();
    options.ip = packetWorldServer.ip;
    options.port = packetWorldServer.port;
    options.worldKey = packetWorldServer.worldKey;
    options.threadName = packetWorldServer.threadName;

    if (not options.ip or not options.port) then
        GGS.INFO("服务器繁忙, 暂无合适的世界服务器提供");
        return;
    end

    -- 登录世界
    if (self:GetWorld()) then 
        self:GetWorld():Login(options);
    end
    
    -- 关闭控制服务器的链接
    self.controlServerConnection:CloseConnection();
end


-- 获取当前认证用户信息
function GeneralGameClient:GetUserInfo()
    return self.userinfo;
end

-- 获取当前系统世界信息
function GeneralGameClient:GetWorldInfo()
    -- return {};
end

-- 是否是匿名用户
function GeneralGameClient:IsAnonymousUser()
    return true;
end

-- 获取用户列表
local playerlist = {}
function GeneralGameClient:GetPlayers()
    local world = self:GetWorld();
    local playerManager = world and world:GetPlayerManager();
    local players = playerManager and playerManager:GetPlayers();
    local count = 0;
    if (players) then
        for _, player in pairs(players) do
            if (player:IsOnline()) then
                count = count + 1;
                playerlist[count] = player;
            end
        end
    end
    local mainPlayer = playerManager:GetMainPlayer();
    if (mainPlayer) then
        count = count + 1;
        playerlist[count] = mainPlayer;
    end
    count = count + 1;
    while(playerlist[count]) do
        playerlist[count] = nil;
        count = count + 1;
    end
    return playerlist;
end

-- 获取网络命令
function GeneralGameClient:GetNetCmdList()
    return self.netCmdList;
end

-- 调试
function GeneralGameClient:Debug(action, cmd_text)
    action = string.lower(action or "");
    if (action == "options" or action == "") then
        return self:ShowDebugInfo(self:GetOptions());
    elseif (action == "userinfo") then
        return self:ShowDebugInfo(self:GetUserInfo());
    elseif (action == "players") then
        return GGS.INFO(self:GetWorld():GetPlayerManager():GetPlayers());
    elseif (action == "syncforceblocklist") then
        local list = {};
        for i = 1, #(self.syncForceBlockList) do
            local x, y, z = BlockEngine:FromSparseIndex(self.syncForceBlockList[i]);
            table.insert(list, string.format("x = %s, y = %s, z = %s", x, y, z));
        end
        return GGS.INFO(list);
    end

    local netHandler = self:GetWorldNetHandler();
    if (not netHandler) then return end
    
    if (action == "worldinfo") then
        netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "WorldInfo"}}));
    elseif (action == "playerinfo") then
        netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "PlayerInfo"}}));
    elseif (action == "serverinfo") then
        netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "ServerInfo"}}));
    elseif (action == "serverlist") then
        netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "ServerList"}}));
    elseif (action == "statistics") then
        netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "StatisticsInfo"}}));
    elseif (action == "ping") then
        netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "ping"}}));
    elseif (action == "serverdebug") then
        local module = CmdParser.ParseString(cmd_text);
        netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "Debug", data = { cmd = "debug", debug = module}}));
    end
end

-- 显示调试信息
function GeneralGameClient:ShowDebugInfo(debug)
    Page.ShowDebugInfoPage({text = GGS.ToString(debug)});
end

-- 初始化成单列模式
GeneralGameClient:InitSingleton();
