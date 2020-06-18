
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
-- NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetClientHandler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Client/EntityMainPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameWorld.lua");

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");

local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameWorld");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local EntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityMainPlayer");
-- local NetClientHandler = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.NetClientHandler"), commonlib.gettable("Mod.GeneralGameServerMod.Client.NetClientHandler"));
local NetClientHandler = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.NetHandler"), commonlib.gettable("Mod.GeneralGameServerMod.Client.NetClientHandler"));

local next_nid = 100;

function NetClientHandler:ctor() 
end

 -- Adds the packet to the send queue
 function NetClientHandler:AddToSendQueue(packet)
    if (not self.disconnected and self.connection) then
        return self.connection:AddPacketToSendQueue(packet);
    end
end

-- clean up connection. 
function NetClientHandler:Cleanup()
    if (self.connection) then
        self.connection:NetworkShutdown();
    end
    self.connection = nil;
	if(self.worldClient) then
	end
end

function NetClientHandler:GetUserName()
	return self.last_username or "";
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

function NetClientHandler:GetNid(ip, port)
    next_nid = next_nid + 1;
    local nid = tostring(next_nid);
    NPL.AddNPLRuntimeAddress({host = tostring(ip), port = tostring(port), nid = nid});
    return nid;
end

-- create a tcp connection to server. 
function NetClientHandler:Init(ip, port, worldId, username, password, worldClient)
    self.worldId = worldId;
    self.worldClient = worldClient;
	
	BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"正在建立链接:%s:%s", ip, port or ""), max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
    self.connection = Connection:new():Init(self:GetNid(ip, port), self);
	self.connection:Connect(5, function(bSucceed)
		-- try authenticate
		if(bSucceed) then
			BroadcastHelper.PushLabel({id="NetClientHandler", label = format(L"成功建立链接:%s:%s", ip, port or ""), max_duration=4000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
            self:AddToSendQueue(Packets.PacketPlayerLogin:new():Init({worldId = worldId, username = username, password = password}));
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


function NetClientHandler:handlePlayerLogin(packetPlayerLogin)
    local result = packetPlayerLogin.result;
    local errmsg = packetPlayerLogin.errmsg or "";
    local username = packetPlayerLogin.username;
    local entityId = packetPlayerLogin.entityId;

    -- 登录失败
    if (result ~= "ok") then
        local text = "登录失败, 无权限或世界人数已满 ".. errmsg;
		BroadcastHelper.PushLabel({id="NetClientHandler", label = text, max_duration=7000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		return self:Cleanup();
    end

    -- 登录成功

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
        entityPlayer:SetPositionAndRotation(x, y, z, facing, pitch);
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
	LOG.std(nil, "info", "NetClientHandler", "client connection error %s", text or "");

	if(text == "ConnectionNotEstablished") then
		BroadcastHelper.PushLabel({id="NetClientHandler", label = L"无法链接到这个服务器", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		_guihelper.MessageBox(L"无法链接到这个服务器,可能该服务器未开启或已关闭.详情请联系该服务器管理员.");
	else --if(text == "OnConnectionLost") then
		if(GameLogic.GetWorld() == self.worldClient) then
			BroadcastHelper.PushLabel({id="NetClientHandler", label = L"与服务器的连接断开了", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ServerPage.lua");
			local ServerPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ServerPage");
			ServerPage.ResetClientInfo()
			local player = EntityManager.GetPlayer()
			if(player) then
				player:SetHeadOnDisplay({url=ParaXML.LuaXML_ParseString(format('<pe:mcml><div style="background-color:red;margin-left:-50px;margin-top:-20">%s</div></pe:mcml>', L"与服务器的连接断开了"))})
			end
			_guihelper.MessageBox(L"已与服务器断开连接,可能服务器已关闭或有其他用户使用该帐号登录.点击\"确定\"返回本地世界",function (result)
--				NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
--				local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
--				InternetLoadWorld.EnterWorld()
				--if(result == _guihelper.DialogResult.Yes) then
				--end
			end,_guihelper.MessageBoxButtons.OK);
			--local player = self.worldClient:GetPlayer();
			--if(player) then
				--player:UpdateDisplayName("oops! ConnectionLost!");
			--end
		else
			-- _guihelper.MessageBox(L"服务器返回错误信息"..(text or ""));
		end
	end
	self:Cleanup();
end