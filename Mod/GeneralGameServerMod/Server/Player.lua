--[[
Title: Player
Author(s): wxa
Date: 2020/6/10
Desc: 世界玩家对象
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/Player.lua");
local Player = commonlib.gettable("GeneralGameServerMod.Server.Player");
Player:new():Init()
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Player = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.Player"));

-- 构造函数
function Player:ctor() 
    self.entityInfo = nil;  -- 实体信息 UI信息
    self.playerInfo = {};   -- 玩家信息 数据信息
    self.dataWatcher = DataWatcher:new();
    self.loginTick = ParaGlobal.timeGetTime();
    self.lastTick = ParaGlobal.timeGetTime();
    self.aliveTime = 0;
    self.state = "online";
end

function Player:Init(entityId, username)
    self.entityId = entityId;
    self.username = username or tostring(entityId);

    return self;
end

function Player:GetUserName() 
    return self.username;
end

function Player:SetPlayerEntityInfo(packetPlayerEntityInfo)
    local isNew = false;
    if not self.entityInfo then
        self.entityInfo = {};
        isNew = true;
    end

    -- 元数据为监控对象列表
    local metadata = packetPlayerEntityInfo:GetMetadata();
    if (metadata) then
        for i = 1, #metadata do
            local obj = metadata[i];
            self.dataWatcher:AddField(obj:GetId(), obj:GetObject());
        end
    end
    
    -- 设置玩家信息
    if (packetPlayerEntityInfo.playerInfo) then
        self:SetPlayerInfo(packetPlayerEntityInfo.playerInfo)
    end

    -- 设置实体信息
    commonlib.partialcopy(self.entityInfo, packetPlayerEntityInfo);
    self.entityInfo.id = nil;
    self.entityInfo.metadata = nil;

    return isNew;
end

function Player:GetPlayerEntityInfo()
    -- Log:Info(self);
    self.entityInfo.playerInfo = self:GetPlayerInfo();
    return Packets.PacketPlayerEntityInfo:new():Init(self.entityInfo, self.dataWatcher, true);
end

function Player:GetPlayerInfo()
    self.playerInfo.entityId = self.entityId; 
    self.playerInfo.state = self.state;
    self.playerInfo.username = self.username;
    return self.playerInfo;
end

function Player:SetPlayerInfo(info)
    commonlib.partialcopy(self.playerInfo, info);
end

function Player:SetNetHandler(netHandler)
    self.playerNetHandler = netHandler;
end

function Player:KickPlayerFromServer(reason)
    return self.playerNetHandler and self.playerNetHandler:KickPlayerFromServer(reason);
end

function Player:SendPacketToPlayer(packet)
    self.playerNetHandler:SendPacketToPlayer(packet);
end

function Player:UpdateTick() 
    self.lastTick = ParaGlobal.timeGetTime();
    self.aliveTime = self.lastTick - self.loginTick;
end

function Player:IsAlive()
    if (self.state == "offline") then return false; end
    
    -- 不能直接使用tick 可能刚登录就退出, 这种tick检测不出
    local aliveDuration = Config.Player.aliveDuration; 
    -- local aliveDuration = 30000;  -- debug
    local curTime = ParaGlobal.timeGetTime();
    if ((curTime - self.lastTick) > aliveDuration) then
        return  false;
    end

    return true;
end

-- 玩家登录
function Player:Login()
    self.loginTick = ParaGlobal.timeGetTime();
    self.state = "online";
end

-- 玩家退出
function Player:Logout() 
    self.logoutTick = ParaGlobal.timeGetTime();
    self.aliveTime = self.logoutTick - self.loginTick;  -- 本次活跃时间
    self.state = "offline";                             -- 状态置为下线
end
