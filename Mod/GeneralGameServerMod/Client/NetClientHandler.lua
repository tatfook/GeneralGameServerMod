
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetClientHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");

local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local NetClientHandler = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.NetClientHandler"), commonlib.gettable("Mod.GeneralGameServerMod.Client.NetClientHandler"));

function NetClientHandler:ctor() 
end

function NetClientHandler:GetWorld()
    return self.worldClient;
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
    local playerId = packetPlayerLogin.playerId;

    -- 只能仿照客户端做  不能使用EntiryPlayerMP 内部会触发后端数据维护
    GameLogic:event(System.Core.Event:new():init("ps_client_login"));

    local entityPlayer = EntityManager.GetPlayer();
    entityPlayer.x = entityPlayer.x or 20000;
    entityPlayer.y = entityPlayer.y or -128;
    entityPlayer.z = entityPlayer.z or 20000;
    entityPlayer:SetUserName(username);
    entityPlayer.rotationPitch = entityPlayer.rotationPitch or 0;

    self:AddToSendQueue(Packets.PacketEntityPlayerSpawn:new():Init(entityPlayer));
end