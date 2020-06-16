
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetClientHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Client/EntityMainPlayer.lua");

local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local EntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityMainPlayer");
local NetClientHandler = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.NetClientHandler"), commonlib.gettable("Mod.GeneralGameServerMod.Client.NetClientHandler"));

function NetClientHandler:ctor() 
end

function NetClientHandler:GetWorld()
    return self.worldClient;
end

function NetClientHandler:GetEntityByID(id)
    return self:GetWorld():GetEntityByID(id);
end

function NetClientHandler:SetPlayer(player)
    self.player = player;
end

function NetClientHandler:GetPlayer() 
    return self.player or EntityManager.GetPlayer();
end

function NetClientHandler:Init(ip, port, username, password, worldClient)
    self.worldClient = worldClient;

	local nid = self:CheckGetNidFromIPAddress(ip, port);
	
	BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"正在建立链接:%s:%s", ip, port or ""), max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
	self.connection = Connection:new():Init(nid, self);
	self.connection:Connect(5, function(bSucceed)
		-- try authenticate
		if(bSucceed) then
			BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"成功建立链接:%s:%s", ip, port or ""), max_duration=4000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
			self:SendLoginPacket(username, password);
		end
    end);
    
	return self;
end

function NetClientHandler:handlePlayerLogout(packetPlayerLogout)
    local username = packetPlayerLogout.username;
    local entityId = packetPlayerLogout.entityId;

    -- 只能仿照客户端做  不能使用EntiryPlayerMP 内部会触发后端数据维护
    GameLogic:event(System.Core.Event:new():init("ps_client_logout"));

    -- 销毁玩家
    local entityPlayer = self:GetEntityPlayer(entityId, username);
    entityPlayer:Destroy();

    return;
end

--[[
client => PacketAuthUser 
server => PacketAuthUser
client => PacketClientLogin
server => PacketLogin
client => PacketEntityPlayerSpawn
server => PacketEntityPlayerSpawn
]]
function NetClientHandler:handlePlayerLogin(packetPlayerLogin)
    local username = packetPlayerLogin.username;
    local entityId = packetPlayerLogin.entityId;

    -- 只能仿照客户端做  不能使用EntiryPlayerMP 内部会触发后端数据维护
    GameLogic:event(System.Core.Event:new():init("ps_client_login"));

    -- 获取旧当前玩家
    local oldEntityPlayer = self:GetPlayer();
    -- 销毁旧当前玩家
    -- if (oldEntityPlayer) then oldEntityPlayer:Destroy(); end
    -- 创建当前玩家
    local entityPlayer = EntityMainPlayer:new():init(self:GetWorld(), self, entityId);
    if(oldEntityPlayer) then
        entityPlayer:SetMainAssetPath(oldEntityPlayer:GetMainAssetPath());
        entityPlayer:SetSkin(oldEntityPlayer:GetSkin());
        entityPlayer:SetGravity(oldEntityPlayer:GetGravity());
        -- entityPlayer:SetPosition(oldEntityPlayer:GetPosition());
        if(entityPlayer:IsShowHeadOnDisplay() and System.ShowHeadOnDisplay) then
            System.ShowHeadOnDisplay(true, entityPlayer:GetInnerObject(), entityPlayer:GetDisplayName(), GameLogic.options.PlayerHeadOnTextColor);	
        end
    end
    entityPlayer:Attach();
    GameLogic.GetPlayerController():SetMainPlayer(entityPlayer);
    self:SetPlayer(entityPlayer);

    -- 上报玩家实体信息
    local dataWatcher  = entityPlayer:GetDataWatcher();
    local metadata = dataWatcher and dataWatcher:GetAllObjectList();
    self:AddToSendQueue(Packets.PacketPlayerEntityInfo:new():Init({
        entityId = entityId,
        x = math.floor(entityPlayer.x or 20000),
        y = math.floor(entityPlayer.y or -128),
        z = math.floor(entityPlayer.z or 20000),
        name = username,
        facing = math.floor(entityPlayer.rotationYaw or entityPlayer.facing or 0),
        pitch = math.floor(entityPlayer.rotationPitch or 0),
        data = metadata and DataWatcher.WriteObjectsInListToData(metadata, nil),
    }));
end

-- 获取玩家实体
function NetClientHandler:GetEntityPlayer(entityId, username)
    local entityPlayer = self:GetPlayer();
    local clientMP = self:GetEntityByID(entityId);
    local world = self:GetWorld();

    if (entityId == entityPlayer.entityId) then
        return entityPlayer, false;
    end
    
    if (not clientMP or not clientMP:isa(EntityManager.EntityPlayerMPOther)) then 
        return EntityManager.EntityPlayerMPOther:new():init(world, username or "", entityId), true;
    end

    return clientMP, false;
end

function NetClientHandler:handlePlayerEntityInfo(packetPlayerEntityInfo)
    if (not packetPlayerEntityInfo) then return end

    local entityId = packetPlayerEntityInfo.entityId;
    local x = packetPlayerEntityInfo.x;
    local y = packetPlayerEntityInfo.y;
    local z = packetPlayerEntityInfo.z;
    local facing = packetPlayerEntityInfo.facing;
    local pitch = packetPlayerEntityInfo.pitch;
    local data = packetPlayerEntityInfo.data;
    local username = packetPlayerEntityInfo.name;

    local mainPlayer = self:GetPlayer();
    local entityPlayer, isNew = self:GetEntityPlayer(entityId, username);
    if (isNew) then
        entityPlayer:Attach();
    end

    -- 更新实体元数据
    if (isNew or entityId ~= mainPlayer.entityId) then
        local watcher = entityPlayer:GetDataWatcher();
        local metadata = data and DataWatcher.ReadWatchebleObjects(data);
        if (watcher and metadata) then 
            watcher:UpdateWatchedObjectsFromList(metadata); 
        end    
        if (entityPlayer:IsDummy()) then
            entityPlayer:FrameMove(0);
        end
    end

    -- 更新位置信息
    -- entityPlayer:SetPositionAndRotation(x, y, z, facing, pitch);
    if (entityId == mainPlayer.entityId) then
        entityPlayer:SetPositionAndRotation(x, y, z, facing, pitch);
    else 
        entityPlayer:SetPositionAndRotation2(x, y, z, facing, pitch, 3);
    end

    local headYaw = packetPlayerEntityInfo.headYaw;
    local headPitch = packetPlayerEntityInfo.headPitch;
    if (entityPlayer.SetTargetHeadRotation and headYaw ~= nil and headPitch ~= nil) then
        entityPlayer:SetTargetHeadRotation(headYaw, headPitch, 3);
    end
end

function NetClientHandler:handlePlayerEntityInfoList(packetPlayerEntityInfoList)
    local playerEntityInfoList = packetPlayerEntityInfoList.playerEntityInfoList;
    for i = 1, #playerEntityInfoList do 
        self:handlePlayerEntityInfo(playerEntityInfoList[i]);
    end
end
