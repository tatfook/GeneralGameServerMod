
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
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityMainPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityOtherPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameWorld.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection");
local EntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer");
local EntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityOtherPlayer");
local NetClientHandler = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.NetHandler"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.NetClientHandler"));

function NetClientHandler:ctor() 
end

 -- Adds the packet to the send queue
 function NetClientHandler:AddToSendQueue(packet)
    if (self.connection) then
        return self.connection:AddPacketToSendQueue(packet);
    end
end

function NetClientHandler:GetUserName()
    return self:GetClient():GetOptions().username;
end

-- clean up connection. 
function NetClientHandler:Cleanup()
    if (self.connection) then
        self.connection:NetworkShutdown();
    end

    local player = self:GetPlayer()
    if(player) then
        player:SetHeadOnDisplay({url=ParaXML.LuaXML_ParseString(string.format('<pe:mcml><div style="background-color:red;margin-left:-50px;margin-top:-20">%s</div></pe:mcml>', L"与服务器的连接断开了"))})
    end

    self.connection = nil;
end

function NetClientHandler:SetWorld(world)
    self.world = world;
end

function NetClientHandler:GetWorld()
    return self.world;
end

function NetClientHandler:GetBlockManager()
    return self:GetWorld():GetBlockManager();
end

function NetClientHandler:SetPlayer(player)
    -- 设置当前玩家
    self.player = player;
end

function NetClientHandler:GetPlayer(entityId) 
    if (not entityId or (self.player and self.player.entityId == entityId)) then
        return self.player; -- 获取当前玩家
    end
    -- 获取指定玩家
    return self:GetWorld():GetEntityByID(entityId)
end

-- 获取玩家ID
function NetClientHandler:GetPlayerId()
    return self:GetPlayer().entityId;
end

-- 是否是当前玩家
function NetClientHandler:IsMainPlayer(entityId)
    local player = self:GetPlayer();
    return player and player.entityId == entityId;
end

-- 获取客户端
function NetClientHandler:GetClient() 
    return self:GetWorld():GetClient();
end

-- create a tcp connection to server. 
function NetClientHandler:Init(world, isReconnection)
    self.isReconnection = isReconnection;
    self:SetWorld(world);
    
    local options = self:GetClient():GetOptions();
    options.ip = options.ip or "127.0.0.1";
	options.port = options.port or "9000";
    options.thread = options.thread or "gl";
    
	BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"正在建立链接:%s:%s", options.ip, options.port or ""), max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
    self.connection = Connection:new():InitByIpPort(options.ip, options.port, self);
	self.connection:Connect(5, function(bSucceed)
		-- try authenticate
		if(bSucceed) then
			BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"成功建立链接:%s:%s", options.ip, options.port or ""), max_duration=4000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
            self:AddToSendQueue(Packets.PacketPlayerLogin:new():Init(options));
        else 
			-- BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"无法建立链接:%s:%s", options.ip, options.port or ""), max_duration=4000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		end
    end);
    
	return self;
end

function NetClientHandler:handlePlayerLogout(packetPlayerLogout)
    local username = packetPlayerLogout.username;
    local entityId = packetPlayerLogout.entityId;

    -- 只能仿照客户端做  不能使用EntiryPlayerMP 内部会触发后端数据维护
    GameLogic:event(System.Core.Event:new():init("ps_client_logout"));

    local player = self:GetPlayer(entityId);
    -- 玩家不存在 直接忽视 
    if (not player) then return end;

    -- 玩家退出
    if (self:GetPlayer() == player) then
        -- 当前玩家
        self:GetWorld():Logout();
        Log:Info("main player logout");
    elseif (player:isa(EntityOtherPlayer)) then
        self:GetWorld():RemoveEntity(player);
        Log:Info("other player logout, entityId: %s", player.entityId);
    else
        -- Log:Info("invalid player entityId: %s", player.entityId);
    end

    return;
end

function NetClientHandler:handlePlayerLogin(packetPlayerLogin)
    local result = packetPlayerLogin.result;
    local errmsg = packetPlayerLogin.errmsg or "";
    local username = packetPlayerLogin.username;
    local entityId = packetPlayerLogin.entityId;

    -- 登录失败
    if (result ~= "ok") then
        local text = "登录失败! " .. errmsg;
		BroadcastHelper.PushLabel({id="NetClientHandler", label = text, max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		return self:GetWorld():Logout();
    end

    -- 登录成功
    local options = self:GetClient():GetOptions();
    options.worldId = packetPlayerLogin.worldId;                       -- 世界ID
    options.parallelWorldName = packetPlayerLogin.parallelWorldName;   -- 平行世界名  可能被客户端改掉
    options.username = packetPlayerLogin.username;

    -- 只能仿照客户端做  不能使用EntiryPlayerMP 内部会触发后端数据维护
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
        local x, y, z = oldEntityPlayer:GetPosition();
        local randomRange = 5;
        if (self.isReconnection) then
            entityPlayer:SetPosition(x, y, z);
        else 
            entityPlayer:SetPosition(x + math.random(-randomRange, randomRange), y, z + math.random(-randomRange, randomRange));
        end
        Log:Info("destroy old player entityId: %d", oldEntityPlayer.entityId);
    else 
        Log:Info("old player no exist!!!");
    end
    entityPlayer:Attach();
    GameLogic.GetPlayerController():SetMainPlayer(entityPlayer);  -- 内部会销毁旧当前玩家
    self:SetPlayer(entityPlayer);
    self:GetWorld():ClearEntityList();
    
    -- 设置玩家信息
    local playerInfo = {
        state = "online",
        username = username,
        userinfo = self:GetClient():GetUserInfo(),
    }
    entityPlayer:SetPlayerInfo(playerInfo);
    
    -- 上报玩家实体信息
    local dataWatcher = entityPlayer:GetDataWatcher();
    self:AddToSendQueue(Packets.PacketPlayerEntityInfo:new():Init({
        entityId = entityId,
        x = math.floor(entityPlayer.x or 20000),
        y = math.floor(entityPlayer.y or -128),
        z = math.floor(entityPlayer.z or 20000),
        name = username or tostring(entityId),
        facing = math.floor(entityPlayer.rotationYaw or entityPlayer.facing or 0),
        pitch = math.floor(entityPlayer.rotationPitch or 0),
        playerInfo = playerInfo,
    }, dataWatcher, true));

    -- 上报玩家选项信息, 定制相关功能的使用
    self:AddToSendQueue(Packets.PacketGeneral:new():Init({
        action = "PlayerOptions",
        data = {
            isSyncBlock = self:GetClient():IsSyncBlock(),
            isSyncCmd = self:GetClient():IsSyncCmd(),
            isAnonymousUser = self:GetClient():IsAnonymousUser(),
        }
    }));

    -- 开始块同步
    if (self:GetClient():IsSyncBlock()) then
       self:GetBlockManager():handleSyncBlock_Begin();
    end

    -- 链接成功取消重连标记
    self.isReconnection = false;
end

-- 获取玩家实体
function NetClientHandler:GetEntityPlayer(entityId, username)
    local mainPlayer = self:GetPlayer();
    local otherPlayer = self:GetPlayer(entityId);
    local world = self:GetWorld();

    if (entityId == mainPlayer.entityId) then
        return mainPlayer, false;
    end
    local EntityOtherPlayerClass = self:GetClient():GetEntityOtherPlayerClass() or EntityOtherPlayerClass;
    if (not otherPlayer or not otherPlayer:isa(EntityOtherPlayer)) then 
        return EntityOtherPlayerClass:new():init(world, username or "", entityId), true;
    end

    return otherPlayer, false;
end

function NetClientHandler:handlePlayerEntityInfo(packetPlayerEntityInfo)
    if (not packetPlayerEntityInfo) then return end

    local entityId = packetPlayerEntityInfo.entityId;
    local x = packetPlayerEntityInfo.x;
    local y = packetPlayerEntityInfo.y;
    local z = packetPlayerEntityInfo.z;
    local facing = packetPlayerEntityInfo.facing;
    local pitch = packetPlayerEntityInfo.pitch;
    local username = packetPlayerEntityInfo.name;

    local mainPlayer = self:GetPlayer();
    local entityPlayer, isNew = self:GetEntityPlayer(entityId, username);
    if (isNew) then
        entityPlayer:SetPositionAndRotation(x, y, z, facing, pitch);
        self:GetWorld():AddEntity(entityPlayer);
    end

    -- 更新实体元数据
    if (isNew or entityId ~= mainPlayer.entityId) then
        local watcher = entityPlayer:GetDataWatcher();
        local metadata = packetPlayerEntityInfo:GetMetadata();
        if (watcher and metadata) then 
            watcher:UpdateWatchedObjectsFromList(metadata); 
        end    
    end

    -- 更新位置信息
    if (x or y or z or facing or pitch) then
        if (entityId == mainPlayer.entityId) then
            entityPlayer:SetPositionAndRotation(x, y, z, facing, pitch);
        else 
            entityPlayer:SetPositionAndRotation2(x, y, z, facing, pitch, 5);
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
    local entityIdList = {};
    local removeEntityList = {};
    -- 创建玩家
    for i = 1, #playerEntityInfoList do
        entityIdList[i] = playerEntityInfoList[i].entityId; 
        self:handlePlayerEntityInfo(playerEntityInfoList[i]);
    end
    -- 同步玩家
    local entityList = self:GetWorld():GetEntityList();
    for i = 1, #entityList do
        local entity = entityList[i];
        -- 重连这里会混乱 所以要加EntityMainPlayer条件  登录成功直接直接清空实体列表就应该不会混乱
        if (entity:isa(EntityOtherPlayer) or entity:isa(EntityMainPlayer)) then   
            local isExist = false;
            for j = 1, #entityIdList do
                if (entityIdList[j] == entity.entityId) then
                    isExist = true;
                    break;
                end
            end
            if (not isExist) then
                removeEntityList[#removeEntityList + 1] = entity;
            end
        end
    end
    for i = 1, #removeEntityList do
        self:GetWorld():RemoveEntity(removeEntityList[i]);
    end
end

-- 处理错误信息
function NetClientHandler:handleErrorMessage(text)
    -- 连接已清说已做过错误处理
    if (not self.connection or GameLogic.GetWorld() ~= self:GetWorld()) then return end
	Log:Info("client connection error %s and nid: %d", text or "", self.connection:GetNid());

	if(text == "ConnectionNotEstablished") then
		BroadcastHelper.PushLabel({id="NetClientHandler", label = L"无法链接到这个服务器", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		_guihelper.MessageBox(L"无法链接到这个服务器,可能该服务器未开启或已关闭.详情请联系该服务器管理员.");
    
        -- 登出世界
        self:GetWorld():Logout();
    elseif (not self.isReconnection) then
        -- 服务器断开链接 极可能是服务器重启更新
        BroadcastHelper.PushLabel({id="NetClientHandler", label = L"与服务器的连接断开了, 3 秒后尝试重新连接...", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
        -- 重连
        commonlib.Timer:new({callbackFunc = function(timer)
            self:Init(self:GetWorld(), true);
        end}):Change(3000, nil);
    end
    
    
end

-- 聊天信息
function NetClientHandler:handleChat(packetChat)
    LOG.std(nil, "debug", "NetClientHandler.handleChat", "%s", packetChat.text);
	Desktop.GetChatGUI():PrintChatMessage(packetChat:ToChatMessage())
end

-- 保持连接活跃
function NetClientHandler:SendTick()
    self:AddToSendQueue(Packets.PacketTick:new():Init());
end

-- 处理玩家信息更新
function NetClientHandler:handlePlayerInfo(packetPlayerInfo)
    local entityId = packetPlayerInfo.entityId;
    local state = packetPlayerInfo.state;

    -- 主要下线  被同账号挤下线
    if (self:IsMainPlayer(entityId)) then
        -- _guihelper.MessageBox(L"账号在其它地方登陆, 若非本人操作请及时修改密码");
        return self:GetWorld():Logout();
    end

    local entityPlayer = self:GetPlayer(entityId);
    if (not entityPlayer or not entityPlayer.SetPlayerInfo) then return end
    entityPlayer:SetPlayerInfo(packetPlayerInfo);
end

-- 处理方块同步
function NetClientHandler:handleGeneral_SyncBlock(packetGeneral)
    local state = packetGeneral.data.state;
    if (state == "SyncBlock_Finish") then
        self:GetBlockManager():handleSyncBlock_Finish();
    elseif (state == "SyncBlock_RequestBlockIndexList") then
        self:GetBlockManager():handleSyncBlock_RequestBlockIndexList(packetGeneral);
    elseif (state == "SyncBlock_ResponseBlockIndexList") then
        self:GetBlockManager():handleSyncBlock_ResponseBlockIndexList(packetGeneral);
    elseif (state == "SyncBlock_RequestSyncBlock") then
        self:GetBlockManager():handleSyncBlock_RequestSyncBlock(packetGeneral);
    elseif (state == "SyncBlock_ResponseSyncBlock") then
        self:GetBlockManager():handleSyncBlock_ResponseSyncBlock(packetGeneral);
    else
    end
end

-- 处理调试信息
function NetClientHandler:handleGeneral_Debug(packetGeneral)
    local cmd = packetGeneral.data.cmd;
    local debug = packetGeneral.data.debug;
    self:GetClient():ShowDebugInfo(debug);
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
end

-- 处理网络命令
function NetClientHandler:handleSyncCmd(packetGeneral)
    local cmd = packetGeneral.data.cmd;
    local opts = packetGeneral.data.opts;
    -- 已存在忽略
    if (self:GetClient():GetNetCmdList():contains(cmd)) then 
        return Log:Info("命令正在执行: " .. cmd); 
    end

    -- 收到命令是起点, 发送命令是终点, 添加到命令列表
    self:GetClient():GetNetCmdList():add(cmd);
    
    -- 开始执行命令
    Log:Debug("begin exec net cmd: " .. cmd);
    self:GetWorld():SetEnableBlockMark(false);
    GameLogic.RunCommand(cmd);
    
    -- 非递归命令
    if (not opts and not opts.recursive) then
        Log:Debug("end exec net cmd: " .. cmd);
        self:GetNetCmdList():removeByValue(cmd);
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
    -- 未开启直接跳出
    if (not self:GetClient():IsSyncBlock()) then return end;
    -- 获取块坐标
    local x, y, z = BlockEngine:FromSparseIndex(packetBlock.blockIndex);
    -- 禁用标记
    self:GetWorld():SetEnableBlockMark(false);
    -- 更新块
    if (packetBlock.blockId) then
        -- 创建或删除都触发相邻块通知事件
        local flag = if_else(packetBlock.blockId == 0 or BlockEngine:GetBlockId(x,y,z) == 0, 3, 0); 
        -- 块数据不存在则使用现有值 
        local blockData = packetBlock.blockData or BlockEngine:GetBlockData(x,y,z);
        -- 设置方块信息
        BlockEngine:SetBlock(x, y, z, packetBlock.blockId, blockData, flag);
    end
    -- 更新块实体
    if (packetBlock.blockEntityPacket) then
        if (packetBlock.blockEntityPacket.ProcessPacket) then
            packetBlock.blockEntityPacket:ProcessPacket(self);
        else
            Log:Error("无效实体数据包");
        end
    end
    -- 启用标记
    self:GetWorld():SetEnableBlockMark(true);
end