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
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Player = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Player"));

Player:Property("Valid", false, "IsValid");

-- 构造函数
function Player:ctor() 
    self.entityInfo = {};  -- 实体信息 UI信息
    self.playerInfo = {};   -- 玩家信息 数据信息
    self.dataWatcher = DataWatcher:new();
    self.loginTick = ParaGlobal.timeGetTime();
    self.lastTick = ParaGlobal.timeGetTime();
    self.aliveTime = 0;
    self.state = "online";
    self.options = {};
    self.areaX = 0;
    self.areaY = 0;
    self.areaZ = 0;
    self.lastBX, self.lastBY, self.lastBZ = nil, nil, nil;
end

function Player:Init(player, playerManager, netHandler)
    self.entityId = player.entityId;
    self.username = player.username or tostring(player.entityId);
    self.playerManager = playerManager;
    self.playerNetHandler = netHandler;

    return self;
end

function Player:GetEntityId()
    return self.entityId;
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

-- 是否使能区域化
function Player:IsEnableArea()
    -- 世界使能区域化, 则玩家必定区域化
    if (self:GetPlayerManager():IsEnableArea()) then return true end
    -- 世界没有使能区域化, 则判断玩家自身是否开启区域化
    return self.options.areaSize ~= nil and self.options.areaSize ~= 0;
end

-- 获取玩家视距
function Player:GetAreaSize()
    -- 未开启区域化直接返回0
    if (not self:IsEnableArea()) then return 0 end
    -- 自身未设置区域大小使用玩家默认的区域大小
    if (self.options.areaSize == nil or self.options.areaSize == 0) then return self:GetPlayerManager():GetAreaSize() end
    -- 返回玩家自身设置的区域大小
    return self.options.areaSize or 0;
end

-- 是否是匿名用户
function Player:IsAnonymousUser()
    return self:GetPlayerInfo().isAnonymousUser;
end

-- 是否保持离线
function Player:IsKeepworkOffline()
    if (self:IsAnonymousUser()) then return false end
    if (IsDevEnv) then return true end
    if (self.aliveTime < Config.Player.minAliveTime) then return false; end
    local userinfo = self:GetUserInfo();
    if (not userinfo or not userinfo.worldCount or userinfo.worldCount < 3) then return false end
    
    return true;
end

function Player:SetPlayerEntityInfo(packetPlayerEntityInfo)
    local isNew = false;

    -- 只有具备实体信息的玩家才有效
    if (not self:IsValid()) then
        self:SetValid(true);
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

    -- 置空无效信息
    self.entityInfo.id = nil;
    self.entityInfo.metadata = nil;

    -- 更新用户区域
    self:UpdatePosInfo();

    return isNew;
end

-- 获取玩家块位置
function Player:GetBlockPos()
    local entityInfo = self:GetEntityInfo();
    return entityInfo.bx or 0,  entityInfo.by or 0, entityInfo.bz or 0;
end

function Player:SetBlockPos(bx, by, bz)
    local entityInfo = self:GetEntityInfo();
    entityInfo.bx,  entityInfo.by, entityInfo.bz = bx, by, bz;
end

function Player:GetPos()
    local entityInfo = self:GetEntityInfo();
    return entityInfo.x, entityInfo.y, entityInfo.z;
end

function Player:SetPos(x, y, z)
    local entityInfo = self:GetEntityInfo();
    entityInfo.x, entityInfo.y, entityInfo.z = x, y, z;
end

function Player:UpdatePosInfo()
    local bx, by, bz = self:GetBlockPos();
    local x, y, z = self:GetPos();
    local distance = 3;
    if (self.lastBX == nil or math.abs(bx - self.lastBX) > distance or math.abs(bz - self.lastBZ) > distance) then
        self.lastBX, self.lastBY, self.lastBZ = bx, by, bz;
        self:GetWorld():GetTrack():AddPosition(bx, by, bz, x, y, z);
    end

    if (not self:IsEnableArea()) then return end
    if (bx == self.oldBX and by == self.oldBY and bz == self.oldBZ) then return end
    self.oldBX, self.oldBY, self.oldBZ = bx, by, bz;
    self:GetPlayerManager():UpdatePlayerPosInfo(self);    
    local areaSize = math.floor(self:GetAreaSize() / 3);
    if (areaSize == 0) then areaSize = 1 end
    local bx = self:GetEntityInfo().bx or 0;
    local bz = self:GetEntityInfo().bz or 0;
    local areaX = math.floor(bx / areaSize);
    local areaZ = math.floor(bz / areaSize);
    if (areaX == self.areaX and areaZ == self.areaZ) then return end
    self.areaX, self.areaZ = areaX, areaZ;
    self:GetPlayerManager():SendPlayerListToPlayer(self);
end

function Player:GetPlayerEntityInfo()
    self.entityInfo.username = self.username;
    self.entityInfo.entityId = self.entityId;
    self.entityInfo.playerInfo = self:GetPlayerInfo();
    return Packets.PacketPlayerEntityInfo:new():Init(self.entityInfo, self.dataWatcher, true);
end

function Player:GetEntityInfo()
    return self.entityInfo;
end

function Player:GetPlayerInfo()
    self.playerInfo.entityId = self.entityId; 
    self.playerInfo.state = self.state;
    self.playerInfo.username = self.username;
    return self.playerInfo;
end

function Player:SetPlayerInfo(info)
    info.state = nil;
    info.username = nil;
    commonlib.partialcopy(self.playerInfo, info);
end

function Player:GetUserInfo()
    return self:GetPlayerInfo().userinfo;
end

function Player:KickPlayerFromServer(reason)
    return self.playerNetHandler:KickPlayerFromServer(reason);
end

function Player:SendPacketToPlayer(packet)
    self.playerNetHandler:SendPacketToPlayer(packet);
end

function Player:UpdateTick() 
    self.lastTick = ParaGlobal.timeGetTime();
    self.aliveTime = self.lastTick - self.loginTick;
end

-- 玩家链接是否存在
function Player:IsConnection()
    return self.playerNetHandler:GetPlayerConnection();
end

-- 是否有效
function Player:IsValid()
    -- 不为在线用户
    if (self.state ~= "online") then return false end
    
    -- 不是在线玩家也无效   保证不是游离玩家
    if (not self:GetPlayerManager():IsOnlinePlayer(self)) then return false end
    
    -- 验证世界不是游离的
    local world = self:GetWorld();
    local worldManager = self.playerNetHandler:GetWorldManager();
    if (worldManager:GetWorldByKey(world:GetWorldKey()) ~= world) then return false end

    return true;
end

-- 是否存活
function Player:IsAlive()
    if (self.state == "offline") then return false; end
    
    -- 不能直接使用tick 可能刚登录就退出, 这种tick检测不出
    local aliveDuration = Config.Player.aliveDuration or 500000; 
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

-- 玩家发送数据包
function Player:SendPacket(packet)
    self.playerNetHandler:SendPacketToPlayer(packet);
end

-- 关闭连接
function Player:CloseConnection()
    -- 关闭玩家链接  服务器主动关闭可以导致玩家活跃后进行重连
    if (self.playerNetHandler:GetPlayerConnection()) then
        self.playerNetHandler:GetPlayerConnection():CloseConnection();
        self.playerNetHandler:SetPlayerConnection(nil);
    end
end
