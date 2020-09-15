
--[[
Title: NetServerHandler
Author(s): wxa
Date: 2020/6/10
Desc: 网络处理程序
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/NetClientHandler.lua");
local NetClientHandler = commonlib.gettable("GeneralGameServerMod.Core.Client.NetClientHandler");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityMainPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityOtherPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameWorld.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection");
local EntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer");
local EntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityOtherPlayer");
local NetClientHandler = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.NetClientHandler"));

NetClientHandler:Property("UserName");       -- 用户名
NetClientHandler:Property("Player");         -- 主玩家
NetClientHandler:Property("World");          -- 世界
NetClientHandler:Property("Client");         -- 客户端
NetClientHandler:Property("BlockManager");   -- 方块管理器
NetClientHandler:Property("PlayerManager");  -- 玩家管理器

local PlayerLoginLogoutDebug = GGS.PlayerLoginLogoutDebug;

function NetClientHandler:ctor() 
    self.reconnectionDelay = 3; -- 3s
    self.isReconnection = false;
end

 -- Adds the packet to the send queue
 function NetClientHandler:AddToSendQueue(packet)
    if (self.connection) then
        return self.connection:AddPacketToSendQueue(packet);
    end
end

-- create a tcp connection to server. 
function NetClientHandler:Init(world)
    -- 设置世界
    self:SetWorld(world);
    -- 设置玩家管理器
    self:SetPlayerManager(self:GetWorld():GetPlayerManager());
    -- 设置客户端
    self:SetClient(self:GetWorld():GetClient());
    -- 设置方块管理器
    self:SetBlockManager(self:GetWorld():GetBlockManager());
    -- 设置用户名
    self:SetUserName(self:GetClient():GetOptions().username);

    -- 连接服务器
    self:Connect();

	return self;
end

function NetClientHandler:handlePlayerLogout(packetPlayerLogout)
    local username = packetPlayerLogout.username;
    local entityId = packetPlayerLogout.entityId;  -- 为空则退出当前玩家
    local reason = packetPlayerLogout.reason;

    -- 只能仿照客户端做  不能使用EntiryPlayerMP 内部会触发后端数据维护
    GameLogic:event(System.Core.Event:new():init("ps_client_logout"));

    PlayerLoginLogoutDebug.Format("player logout, username: %s, entityId: %s, reason: %s", username, entityId, reason);

    -- 主玩家退出
    if (self:GetPlayer().entityId == entityId) then
        return self:GetWorld():Logout();
    end

    local player = self:GetPlayerManager():GetPlayerByUserName(username);

    -- 玩家不存在 直接忽视 
    if (not player or player.entityId ~= entityId) then return PlayerLoginLogoutDebug("player logout and player no exist!!!") end;

    -- 移除玩家
    self:GetPlayerManager():RemovePlayer(player);

    return;
end

function NetClientHandler:handlePlayerLogin(packetPlayerLogin)
    local result = packetPlayerLogin.result;
    local errmsg = packetPlayerLogin.errmsg or "";
    local username = packetPlayerLogin.username;
    local entityId = packetPlayerLogin.entityId;
    local areaSize = packetPlayerLogin.areaSize;

    -- 登录失败
    if (result ~= "ok") then
        local text = "登录失败! " .. errmsg;
        BroadcastHelper.PushLabel({id="NetClientHandler", label = text, max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
        PlayerLoginLogoutDebug("登录失败, 退出联机世界");
		return self:GetWorld():Logout();
    end

    PlayerLoginLogoutDebug.Format("player login success, username: %s, entityId: %s, areaSize: %s", username, entityId, areaSize);
    
    -- 登录成功
    local options = self:GetClient():GetOptions();
    options.worldId = packetPlayerLogin.worldId;                       -- 世界ID
    options.worldName = packetPlayerLogin.worldName;                   -- 平行世界名  可能被客户端改掉
    options.username = packetPlayerLogin.username;
    options.areaSize = packetPlayerLogin.areaSize or 0; 

    self:SetUserName(options.username);

    -- 只能仿照客户端做  不能使用EntityPlayerMP 内部会触发后端数据维护
    GameLogic:event(System.Core.Event:new():init("ps_client_login"));

    -- 获取旧当前玩家
    local oldEntityPlayer = EntityManager.GetPlayer();
    -- 创建当前玩家
    local EntityMainPlayerClass = self:GetClient():GetEntityMainPlayerClass() or EntityMainPlayer;
    local entityPlayer = EntityMainPlayerClass:new():init(self:GetWorld(), self, entityId);
    if(oldEntityPlayer) then
        local oldMainAssetPath = oldEntityPlayer:GetMainAssetPath();
        entityPlayer:SetMainAssetPath(if_else(not oldMainAssetPath or oldMainAssetPath == "", "character/CC/02human/paperman/boy01.x", oldMainAssetPath));
        entityPlayer:SetSkin(oldEntityPlayer:GetSkin());
        entityPlayer:SetGravity(oldEntityPlayer:GetGravity());
        entityPlayer:SetScaling(oldEntityPlayer:GetScaling());
        entityPlayer:SetSpeedScale(oldEntityPlayer:GetSpeedScale());
        local x, y, z = oldEntityPlayer:GetPosition();
        local randomRange = 5;
        if (oldEntityPlayer:isa(EntityMainPlayerClass)) then
            entityPlayer:SetPosition(x, y, z);
        else 
            entityPlayer:SetPosition(x + math.random(-randomRange, randomRange), y, z + math.random(-randomRange, randomRange));
        end
    end

    -- 设置主玩家
    entityPlayer:Attach();
    GameLogic.GetPlayerController():SetMainPlayer(entityPlayer);  -- 内部会销毁旧当前玩家
    self:GetPlayerManager():SetMainPlayer(entityPlayer);
    self:GetPlayerManager():SetAreaSize(areaSize);
    self:SetPlayer(entityPlayer);
 
    -- 清空玩家列表
    self:GetPlayerManager():ClearPlayers();
    
    -- 设置玩家信息
    local playerInfo = {
        state = "online",
        username = username,
        isAnonymousUser = self:GetClient():IsAnonymousUser(),
        userinfo = self:GetClient():GetUserInfo(),
    }
    entityPlayer:SetPlayerInfo(playerInfo);
    
    -- 上报玩家实体信息
    local dataWatcher = entityPlayer:GetDataWatcher();
    local bx, by, bz = entityPlayer:GetBlockPos();
    self:AddToSendQueue(Packets.PacketPlayerEntityInfo:new():Init({
        entityId = entityId,
        x = math.floor(entityPlayer.x or 20000),
        y = math.floor(entityPlayer.y or -128),
        z = math.floor(entityPlayer.z or 20000),
        bx = bx, by = by, bz = bz,
        name = username or tostring(entityId),
        facing = math.floor(entityPlayer.rotationYaw or entityPlayer.facing or 0),
        pitch = math.floor(entityPlayer.rotationPitch or 0),
        playerInfo = playerInfo,
    }, dataWatcher, true));
end

-- 获取玩家实体
function NetClientHandler:GetEntityPlayer(entityId, username)
    local mainPlayer = self:GetPlayer();
    local otherPlayer = self:GetPlayerManager():GetPlayerByUserName(username) or self:GetPlayerManager():GetPlayerByEntityId(entityId);
    local world = self:GetWorld();

    -- 是否是主玩家
    if (entityId == mainPlayer.entityId) then
        return mainPlayer, false;
    end

    -- PlayerLoginLogoutDebug.Format("get other player: entityId: %s, username: %s, isExist: %s", entityId, username, otherPlayer ~= nil);
    local EntityOtherPlayerClass = self:GetClient():GetEntityOtherPlayerClass() or EntityOtherPlayer;
    if (not otherPlayer) then 
        return EntityOtherPlayerClass:new():init(world, username or "", entityId), true;
    end

    -- 实时更新entityId username  保证 entityId username 的正确性
    otherPlayer.entityId = entityId or otherPlayer.entityId;  
    otherPlayer:SetUserName(username or otherPlayer:GetUserName());

    return otherPlayer, false;
end

-- 用户实体信息
function NetClientHandler:handlePlayerEntityInfo(packetPlayerEntityInfo)
    if (not packetPlayerEntityInfo) then return end

    local entityId, username = packetPlayerEntityInfo.entityId, packetPlayerEntityInfo.username;
    local x, y, z, facing, pitch, tick = packetPlayerEntityInfo.x, packetPlayerEntityInfo.y, packetPlayerEntityInfo.z, packetPlayerEntityInfo.facing, packetPlayerEntityInfo.pitch, packetPlayerEntityInfo.tick or 5;
    local bx, by, bz = packetPlayerEntityInfo.bx, packetPlayerEntityInfo.by, packetPlayerEntityInfo.bz;
    
    -- 为主玩家不做处理
    if (entityId == self:GetPlayer().entityId) then return end
    
    -- 不在可视区则移除玩家
    if (bx and by and bz and not self:GetPlayerManager():IsInnerVisibleArea(bx, by, bz)) then return self:GetPlayerManager():RemovePlayer(username) end
    
    -- 获取玩家实体
    local entityPlayer, isNew = self:GetEntityPlayer(entityId, username);

    -- 新用户加入玩家管理器
    if (isNew) then
        self:GetPlayerManager():AddPlayer(entityPlayer);
    end
    
    -- 更新玩家运动动画
    if (type(entityPlayer.SetMotionAnimId) == "function") then entityPlayer:SetMotionAnimId(packetPlayerEntityInfo.motionAnimId) end

    -- 更新实体元数据
    local watcher = entityPlayer:GetDataWatcher();
    local metadata = packetPlayerEntityInfo:GetMetadata();
    if (watcher and metadata) then 
        watcher:UpdateWatchedObjectsFromList(metadata); 
    end    

    -- 更新位置信息
    if (x or y or z or facing or pitch) then
        local oldpos = string.format("%.2f %.2f %.2f", entityPlayer.x or 0, entityPlayer.y or 0, entityPlayer.z or 0);
        local newpos = string.format("%.2f %.2f %.2f", x, y, z);
        if (isNew or oldpos == newpos) then 
            entityPlayer:SetPositionAndRotation(x, y, z, facing, pitch);  -- 第一次需要用此函数避免飘逸
        else
            entityPlayer:SetPositionAndRotation2(x, y, z, facing, pitch, tick);
        end
    end

    -- 头部信息
    local headYaw = packetPlayerEntityInfo.headYaw;
    local headPitch = packetPlayerEntityInfo.headPitch;
    if (entityPlayer.SetTargetHeadRotation and headYaw ~= nil and headPitch ~= nil) then
        entityPlayer:SetTargetHeadRotation(headYaw, headPitch, 3);
    end

    -- 设置玩家信息
    if (packetPlayerEntityInfo.playerInfo) then
        entityPlayer:SetPlayerInfo(packetPlayerEntityInfo.playerInfo);
    end
end

-- 处理世界玩家列表
function NetClientHandler:handlePlayerEntityInfoList(packetPlayerEntityInfoList)
    local playerEntityInfoList = packetPlayerEntityInfoList.playerEntityInfoList;
    local usernames = {};
    local deleted = {};
    -- 更新玩家信息
    for i = 1, #playerEntityInfoList do
        local username = playerEntityInfoList[i].username; 
        if (username) then
            usernames[username] = true;
            self:handlePlayerEntityInfo(playerEntityInfoList[i]);
        end 
    end
    -- 查找无效玩家
    local players = self:GetPlayerManager():GetPlayers();
    local mainPlayer = self:GetPlayer();
    for username, player in pairs(players) do
        if (not usernames[username]) then
            table.insert(deleted, player);
        end
    end
    -- 移除无效玩家
    for i = 1, #deleted do
        self:GetPlayerManager():RemovePlayer(deleted[i]);
    end
end

-- 聊天信息
function NetClientHandler:handleChat(packetChat)
    LOG.std(nil, "debug", "NetClientHandler.handleChat", "%s", packetChat.text);
	Desktop.GetChatGUI():PrintChatMessage(packetChat:ToChatMessage())
end

-- 处理玩家信息更新
function NetClientHandler:handlePlayerInfo(packetPlayerInfo)
    local entityId = packetPlayerInfo.entityId;
    local entityPlayer = self:GetPlayerManager():GetPlayerByEntityId(entityId);
    if (not entityPlayer or not entityPlayer.SetPlayerInfo) then return end
    entityPlayer:SetPlayerInfo(packetPlayerInfo);
end

-- 处理方块同步
function NetClientHandler:handleGeneral_SyncBlock(packetGeneral)
    local state = packetGeneral.data.state;
    if (state == "SyncBlock_Begin") then
        self:GetBlockManager():handleSyncBlock_Begin();
    elseif (state == "SyncBlock_RequestBlockIndexList") then
        self:GetBlockManager():handleSyncBlock_RequestBlockIndexList(packetGeneral);
    elseif (state == "SyncBlock_ResponseBlockIndexList") then
        self:GetBlockManager():handleSyncBlock_ResponseBlockIndexList(packetGeneral);
    elseif (state == "SyncBlock_RequestSyncBlock") then
        self:GetBlockManager():handleSyncBlock_RequestSyncBlock(packetGeneral);
    elseif (state == "SyncBlock_ResponseSyncBlock") then
        self:GetBlockManager():handleSyncBlock_ResponseSyncBlock(packetGeneral);
    elseif (state == "SyncBlock_Finish") then
        self:GetBlockManager():handleSyncBlock_Finish();else
    end
end


-- 处理方块点击
function NetClientHandler:handleGeneral(packetGeneral)
    local action = packetGeneral.action;
    if (action == "SyncCmd") then 
        self:handleSyncCmd(packetGeneral);
    elseif (action == "SyncBlock") then
        self:handleGeneral_SyncBlock(packetGeneral);
    elseif (action == "ServerWorldList") then
        self:GetClient():handleServerWorldList(packetGeneral);
    elseif (action == "Debug") then
        self:handleGeneral_Debug(packetGeneral);
    end
    -- 直接重新登录
    if (packetGeneral:IsReloginPacket()) then
        self:Login();
    end
end

-- 处理网络命令
function NetClientHandler:handleSyncCmd(packetGeneral)
    local cmd = packetGeneral.data.cmd;
    local opts = packetGeneral.data.opts;
    -- 已存在忽略
    if (self:GetClient():GetNetCmdList():contains(cmd)) then 
        return GGS.INFO("命令正在执行: " .. cmd); 
    end

    -- 收到命令是起点, 发送命令是终点, 添加到命令列表
    self:GetClient():GetNetCmdList():add(cmd);
    
    -- 开始执行命令
    GGS.DEBUG("begin exec net cmd: " .. cmd);
    self:GetWorld():SetEnableBlockMark(false);
    GameLogic.RunCommand(cmd);
    
    -- 非递归命令
    if (not opts or not opts.recursive) then
        GGS.DEBUG("end exec net cmd: " .. cmd);
        self:GetClient():GetNetCmdList():removeByValue(cmd);
    end

    self:GetWorld():SetEnableBlockMark(true);
end

-- 方块数据同步
function NetClientHandler:handleUpdateEntitySign(packet_UpdateEntitySign)
	local blockEntity = EntityManager.GetBlockEntity(packet_UpdateEntitySign.x, packet_UpdateEntitySign.y, packet_UpdateEntitySign.z)
	if(blockEntity) then blockEntity:OnUpdateFromPacket(packet_UpdateEntitySign); end
end
-- 方块数据同步
function NetClientHandler:handleUpdateEntityBlock(packet_UpdateEntityBlock)
    local blockEntity = EntityManager.GetBlockEntity(packet_UpdateEntityBlock.x, packet_UpdateEntityBlock.y, packet_UpdateEntityBlock.z)
	if(blockEntity) then blockEntity:OnUpdateFromPacket(packet_UpdateEntityBlock); end
end

-- 处理块信息更新
function NetClientHandler:handleBlock(packetBlock)
    local isSyncForceBlock = self:GetClient():IsSyncForceBlock() and self:GetBlockManager():IsSyncForceBlock(packetBlock.blockIndex);
    -- 未开启直接跳出
    if (not isSyncForceBlock and not self:GetClient():IsSyncBlock()) then return end;
    -- 获取块坐标
    local x, y, z = BlockEngine:FromSparseIndex(packetBlock.blockIndex);
    local blockId = packetBlock.blockId or BlockEngine:GetBlockId(x,y,z);
    local blockData = packetBlock.blockData or BlockEngine:GetBlockData(x,y,z); -- 块数据不存在则使用现有值 
    -- 禁用标记
    self:GetWorld():SetEnableBlockMark(false);
    -- 更新块
    if (packetBlock.blockId) then
        -- 创建或删除都触发相邻块通知事件
        local flag = packetBlock.blockFlag or if_else(packetBlock.blockId == 0 or BlockEngine:GetBlockId(x,y,z) == 0, 3, 0); 
        -- 设置方块信息
        BlockEngine:SetBlock(x, y, z, packetBlock.blockId, blockData, flag);
    end
    -- 更新块实体
    if (packetBlock.blockEntityPacket) then
        if (packetBlock.blockEntityPacket.ProcessPacket) then
            packetBlock.blockEntityPacket:ProcessPacket(self);
        else
            GGS.WARN("无效实体数据包");
        end
    end
    -- 设置块信息
    self:GetBlockManager():SetBlock(x, y, z, blockId, blockData, packetBlock.blockEntityPacket);
    -- 启用标记
    self:GetWorld():SetEnableBlockMark(true);
end


-- 保持连接活跃
function NetClientHandler:SendTick()
    local player = self:GetPlayer();
    if (not player or not player:isa(EntityMainPlayer)) then return end
    self:AddToSendQueue(self:GetPlayer():GetPacketPlayerEntityInfo());
end

-- 登录
function NetClientHandler:Login()
    local options = self:GetClient():GetOptions();
    self:AddToSendQueue(Packets.PacketPlayerLogin:new():Init({
        username = options.username,
        password = options.password,
        worldId = options.worldId,
        worldName = options.worldName,
        worldType = options.worldType,
        options = {
            isSyncBlock = options.isSyncBlock,
            isSyncForceBlock = options.isSyncForceBlock,
            isSyncCmd = options.isSyncCmd,
            areaSize = options.areaSize,
        }
    }));
end

-- 与服务器建立链接
function NetClientHandler:Connect()
    local options = self:GetClient():GetOptions();

    -- 在连接中直接返回
    if (self.isConnecting) then return end;
    self.isConnecting = true;

    -- 获取连接
    self.connection = Connection:new():InitByIpPort(options.ip, options.port, self);
    -- 连接成功
    if (self.connection:Connect() == 0) then 
        self:Login();
        self.isConnecting = false;
        self.isReconnection = false;
        self.reconnectionDelay = 3;
        PlayerLoginLogoutDebug("与服务器成功建立链接");
        return 
    end

    -- 重连
    commonlib.Timer:new({callbackFunc = function(timer)
        self.isConnecting = false;
        self:Connect();
        -- 最大重连间隔为10分钟
        self.reconnectionDelay = self.reconnectionDelay + self.reconnectionDelay;
        if (self.reconnectionDelay > 600) then self.reconnectionDelay = 600 end
        -- 开发环境每次5秒
        if (GGS.IsDevEnv) then self.reconnectionDelay = 5 end
    end}):Change(self.reconnectionDelay * 1000, nil);
end

-- 处理错误信息
function NetClientHandler:handleErrorMessage(text)
    -- 连接已清说已做过错误处理
    PlayerLoginLogoutDebug(string.format("client connection error %s and nid: %s, isConntectionWorld: %s", text or "", self.connection and self.connection:GetNid() or 0, GameLogic.GetWorld() == self:GetWorld()));
    
    -- 离线
    self:Offline();
    
    if (not self.connection or GameLogic.GetWorld() ~= self:GetWorld()) then return end

    -- 第一次重连提醒
    if (not self.isReconnection) then BroadcastHelper.PushLabel({id="NetClientHandler", label = L"与服务器断开连接, 稍后尝试重新连接...", max_duration=6000, color = "177 177 177", scaling=1.1, bold=true, shadow=true,}) end

    -- 打印重连接时间间隔
    PlayerLoginLogoutDebug(string.format("exec reconnect after %d second", self.reconnectionDelay));

    -- 重连
    self.isReconnection = true;
    self:Connect();
end

-- clean up connection. 
function NetClientHandler:Cleanup()
    -- 关闭连接
    if (self.connection) then
        self.connection:NetworkShutdown();
        self.connection = nil;
    end

    -- 离线
    self:Offline();

    PlayerLoginLogoutDebug.Format("main player logout, username = %s", self:GetUserName());
end

-- 玩家离线状态
function NetClientHandler:Offline()
    -- 清除其它玩家
    self:GetPlayerManager():ClearPlayers();

    -- 调整当前玩家样式
    if (not self:GetPlayer()) then return end;
    
    -- 灰化用户名
    self:GetPlayer():SetHeadOnDisplay({url=ParaXML.LuaXML_ParseString(string.format([[
    <pe:mcml>
        <div style="width: 200px; margin-left: -100px; margin-top:-40px;">
            <div style="text-align:center; color: #b1b1b1; base-font-size:20px; font-size:20px;">%s</div>
            <div style="text-align:center; color: #ff0000; base-font-size:14px; font-size:14px;">已掉线, 处于离线模式中.</div>
        </div>
    </pe:mcml>]], self:GetUserName()))});
end


-- 处理调试信息
function NetClientHandler:handleGeneral_Debug(packetGeneral)
    local cmd = packetGeneral.data.cmd;
    local debug = packetGeneral.data.debug;
    GGS.INFO(cmd, debug);
    -- 信息太多进行屏蔽
    if (cmd == "WorldInfo") then debug.players = nil end
    self:GetClient():ShowDebugInfo(debug);
end