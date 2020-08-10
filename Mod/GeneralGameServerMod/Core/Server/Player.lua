--[[
Title: Player
Author(s): wxa
Date: 2020/6/10
Desc: 世界玩家对象
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/Player.lua");
local Player = commonlib.gettable("GeneralGameServerMod.Core.Server.Player");
Player:new():Init()
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Player = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Player"));

-- 构造函数
function Player:ctor() 
    self.entityInfo = nil;  -- 实体信息 UI信息
    self.playerInfo = {};   -- 玩家信息 数据信息
    self.dataWatcher = DataWatcher:new();
    self.loginTick = ParaGlobal.timeGetTime();
    self.lastTick = ParaGlobal.timeGetTime();
    self.aliveTime = 0;
    self.state = "online";
    self.options = {};
end

function Player:Init(player, playerManager, netHandler)
    self.entityId = player.entityId;
    self.username = player.username or tostring(player.entityId);
    self.playerManager = playerManager;
    self.playerNetHandler = netHandler;

    return self;
end

function Player:GetUserName() 
    return self.username;
end

function Player:GetPlayerManager()
    return self.playerManager;
end

function Player:GetWorld()
    return self:GetPlayerManager():GetWorld();
end

-- 设置玩家选项
function Player:SetOptions(options)
    -- -- 设置块同步开始时间
    -- if (self.options.isSyncBlock ~= options.isSyncBlock) then
    --     if (options.isSyncBlock) then
    --         self.syncBlockTime = ParaGlobal.timeGetTime();
    --     else
    --         self.syncBlockTime = nil;
    --     end
    -- end

    commonlib.partialcopy(self.options, options);
end

-- 设置块同步完成
function Player:SetSyncBlockFinish()
    self.isSyncBlockFinish = true;
    self.syncBlockTime = ParaGlobal.timeGetTime();
end

-- 是否块同步完成
function Player:IsSyncBlockFinish()
    return self.isSyncBlockFinish;
end

-- 是否同步方块
function Player:IsSyncBlock()
    return self.options.isSyncBlock;
end

-- 是否同步命令
function Player:IsSyncCmd()
    return self.options.isSyncCmd;
end

-- 是否是匿名用户
function Player:IsAnonymousUser()
    return self:GetPlayerInfo().isAnonymousUser;
end

-- 是否保持离线
function Player:IsKeepworkOffline()
    if (self:IsAnonymousUser()) then return false; end
    if (self.aliveTime < Config.Player.minAliveTime) then return false; end
    local userinfo = self:GetUserInfo();
    if (not userinfo or not userinfo.worldCount or userinfo.worldCount < 3) then return false end
    
    return true;
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

function Player:GetUserInfo()
    return self:GetPlayerInfo().userinfo;
end

function Player:SetPlayerInfo(info)
    info.state = nil;
    info.username = nil;
    commonlib.partialcopy(self.playerInfo, info);
end

function Player:KickPlayerFromServer(reason)
    Log:Info("player kick; username : %s, worldkey: %s", self:GetUserName(), self:GetWorld():GetWorldKey());
    return self.playerNetHandler:KickPlayerFromServer(reason);
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
