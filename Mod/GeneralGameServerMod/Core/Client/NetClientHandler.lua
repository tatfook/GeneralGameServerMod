
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
    return self.options.username;
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
function NetClientHandler:Init(options, world, isReconnection)
    self.options = options;
    self.isReconnection = isReconnection;
    self:SetWorld(world);
	
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
        player:Destroy();
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
    self.options.worldId = packetPlayerLogin.worldId;                       -- 世界ID
    self.options.parallelWorldName = packetPlayerLogin.parallelWorldName;   -- 平行世界名  可能被客户端改掉

    -- 只能仿照客户端做  不能使用EntiryPlayerMP 内部会触发后端数据维护
    GameLogic:event(System.Core.Event:new():init("ps_client_login"));

    -- 获取旧当前玩家
    local oldEntityPlayer = EntityManager.GetPlayer();
    -- 创建当前玩家
    local EntityMainPlayerClass = self:GetClient():GetEntityMainPlayerClass() or EntityMainPlayer;
    local entityPlayer = EntityMainPlayerClass:new():init(self:GetWorld(), self, entityId);
    if(oldEntityPlayer) then
        entityPlayer:SetMainAssetPath(oldEntityPlayer:GetMainAssetPath());
        entityPlayer:SetSkin(oldEntityPlayer:GetSkin());
        entityPlayer:SetGravity(oldEntityPlayer:GetGravity());
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
        }
    }));
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
        entityPlayer:Attach();
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
    -- 创建玩家
    for i = 1, #playerEntityInfoList do
        entityIdList[i] = playerEntityInfoList[i].entityId; 
        self:handlePlayerEntityInfo(playerEntityInfoList[i]);
    end
    -- 同步玩家
    local entityList = self:GetWorld():GetEntityList();
    for i = 1, #entityList do
        local entity = entityList[i];
        if (entity:isa(EntityOtherPlayer)) then
            local isExist = false;
            for j = 1, #entityIdList do
                if (entityIdList[j] == entity.entityId) then
                    isExist = true;
                    break;
                end
            end
            if (not isExist) then
                entity:Destroy();
            end
        end
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
    else 
        -- 服务器断开链接 极可能是服务器重启更新
        BroadcastHelper.PushLabel({id="NetClientHandler", label = L"与服务器的连接断开了, 3 秒后尝试重新连接...", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
        -- 重连
        commonlib.Timer:new({callbackFunc = function(timer)
            self:Init(self.options, self:GetWorld(), true);
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
    if (not entityPlayer) then return end;
    entityPlayer:SetPlayerInfo(packetPlayerInfo);
end

-- 处理方块点击
function NetClientHandler:handleGeneral(packetGeneral)
    local packetData = packetGeneral.data;
    local action = packetGeneral.action;
    if (action == "SyncCmd") then 
        GameLogic.RunCommand(packetData);
    end
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
        BlockEngine:SetBlock(x, y, z, packetBlock.blockId, packetBlock.blockData or BlockEngine:GetBlockData(x,y,z));
    end
    -- 更新块实体
    if (packetBlock.blockEntityPacket) then
        packetBlock.blockEntityPacket:ProcessPacket(self);
    end
    -- 启用标记
    self:GetWorld():SetEnableBlockMark(true);
end