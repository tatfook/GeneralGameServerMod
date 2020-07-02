

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Client/EntityMainPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Client/EntityOtherPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameWorld.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameWorld");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local EntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityMainPlayer");
local EntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityOtherPlayer");
local NetClientHandler = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.NetHandler"), commonlib.gettable("Mod.GeneralGameServerMod.Client.NetClientHandler"));

function NetClientHandler:ctor() 
end

 -- Adds the packet to the send queue
 function NetClientHandler:AddToSendQueue(packet)
    if (self.connection) then
        return self.connection:AddPacketToSendQueue(packet);
    end
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
	self:SetWorld(nil);
end

-- 连接是否有效
function NetClientHandler:IsValidConnection()
    return self.connection and true or false;
end

function NetClientHandler:GetUserName()
	return self.last_username or "";
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
        -- 获取当前玩家
        return self.player;
    end
    -- 获取指定玩家
    return self:GetWorld():GetEntityByID(entityId)
end

-- 是否是当前玩家
function NetClientHandler:IsCurrentPlayer(entityId)
    return self:GetPlayer().entityId == entityId;
end

-- create a tcp connection to server. 
function NetClientHandler:Init(options, world)
    self.options = options;
    self:SetWorld(world);
	
	BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"正在建立链接:%s:%s", options.ip, options.port or ""), max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
    self.connection = Connection:new():InitByIpPort(options.ip, options.port, self);
	self.connection:Connect(5, function(bSucceed)
		-- try authenticate
		if(bSucceed) then
			BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"成功建立链接:%s:%s", options.ip, options.port or ""), max_duration=4000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
            self:AddToSendQueue(Packets.PacketPlayerLogin:new():Init(options));
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
    else 
        player:Destroy();
        self:GetWorld():RemoveEntity(player);
        Log:Info("other player logout");
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
    local entityPlayer = EntityMainPlayer:new():init(self:GetWorld(), self, entityId);
    if(oldEntityPlayer) then
        entityPlayer:SetMainAssetPath(oldEntityPlayer:GetMainAssetPath());
        entityPlayer:SetSkin(oldEntityPlayer:GetSkin());
        entityPlayer:SetGravity(oldEntityPlayer:GetGravity());
        local x, y, z = oldEntityPlayer:GetPosition();
        local randomRange = 10;
        entityPlayer:SetPosition(x + math.random(-randomRange, randomRange), y, z + math.random(-randomRange, randomRange));
        if(entityPlayer:IsShowHeadOnDisplay() and System.ShowHeadOnDisplay) then
            System.ShowHeadOnDisplay(true, entityPlayer:GetInnerObject(), entityPlayer:GetDisplayName(), GameLogic.options.PlayerHeadOnTextColor);	
        end
    end
    entityPlayer:Attach();
    GameLogic.GetPlayerController():SetMainPlayer(entityPlayer);  -- 内部会销毁旧当前玩家
    oldEntityPlayer:Destroy(); -- 手动销毁旧玩家
    self:SetPlayer(entityPlayer);
    
    -- 设置玩家信息
    entityPlayer:SetPlayerInfo({state = "online", username = username});
    
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
    }, dataWatcher, true));
end

-- 获取玩家实体
function NetClientHandler:GetEntityPlayer(entityId, username)
    local mainPlayer = self:GetPlayer();
    local otherPlayer = self:GetPlayer(entityId);
    local world = self:GetWorld();

    if (entityId == mainPlayer.entityId) then
        return mainPlayer, false;
    end
    
    if (not otherPlayer or not otherPlayer:isa(EntityOtherPlayer)) then 
        return EntityOtherPlayer:new():init(world, username or "", entityId), true;
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

function NetClientHandler:handlePlayerEntityInfoList(packetPlayerEntityInfoList)
    local playerEntityInfoList = packetPlayerEntityInfoList.playerEntityInfoList;
    for i = 1, #playerEntityInfoList do 
        self:handlePlayerEntityInfo(playerEntityInfoList[i]);
    end
end

-- 处理块信息更新
function NetClientHandler:handleBlockInfoList(packetBlockInfoList)
    local blockInfoList = packetBlockInfoList.blockInfoList;

    -- 禁用标记
    self:GetWorld():SetEnableBlockMark(false);
    -- 更新世界块
    for i = 1, #(blockInfoList) do
        local block = blockInfoList[i];
        local x, y, z = BlockEngine:FromSparseIndex(block.blockIndex);
		BlockEngine:SetBlock(x, y, z, block.blockId, block.blockData);
    end
    -- 启用标记
    self:GetWorld():SetEnableBlockMark(true);
end

function NetClientHandler:handleErrorMessage(text)
    -- 连接已清说已做过错误处理
    if (not self.connection or GameLogic.GetWorld() ~= self:GetWorld()) then return end
	Log:Info("client connection error %s and nid: %d", text or "", self.connection:GetNid());

	if(text == "ConnectionNotEstablished") then
		BroadcastHelper.PushLabel({id="NetClientHandler", label = L"无法链接到这个服务器", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		_guihelper.MessageBox(L"无法链接到这个服务器,可能该服务器未开启或已关闭.详情请联系该服务器管理员.");
    else 
        BroadcastHelper.PushLabel({id="NetClientHandler", label = L"与服务器的连接断开了", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
    end
    
    -- 登出世界
    self:GetWorld():Logout();
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
    local entityPlayer = self:GetPlayer(entityId);
    entityPlayer:SetPlayerInfo(packetPlayerInfo);
end
