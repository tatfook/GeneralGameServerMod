--[[
Title: entity player multiplayer client
Author(s): wxa
Date: 2020/6/15
Desc: the main player entity on the client side. 
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityMainPlayer.lua");
local EntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/AssetsWhiteList.lua");
local AssetsWhiteList = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.AssetsWhiteList");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local EntityMainPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPClient"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer"));

local maxMotionUpdateTickCount = 33;

EntityMainPlayer:Property("UpdatePlayerInfo", false, "IsUpdatePlayerInfo");
EntityMainPlayer:Property("World");

-- 构造函数
function EntityMainPlayer:ctor()
    self.playerInfo = {};
    self.oldXYZ = "";
    self.lastMoved = false;
    self.lastXYZ = "";
    self.lastX, self.lastY, self.lastZ = 0, 0, 0;
    self.motionUpdateTickCount = 0;
    self.lastMotionUpdateTickCount = 1;
    self.motionPacketList = Packets.PacketPlayerEntityInfoList:new():Init(nil, "SyncPlayerPosition");
end

-- 初始化函数
function EntityMainPlayer:init(world, netHandler, entityId)
    EntityMainPlayer._super.init(self, world, netHandler, entityId);
    
    self:SetSkipPicking(not self:IsCanClick());
    self:SetWorld(world);

    return self;
end

-- 发送网络数据包
function EntityMainPlayer:AddToSendQueue(packet)
    EntityMainPlayer._super.AddToSendQueue(self, packet);
end

-- 是否可以被点击
function EntityMainPlayer:IsCanClick() 
    return false;
end

-- 是否可以飞行
function EntityMainPlayer:IsCanFlying()
    return false;
end

-- 设置玩家信息
function EntityMainPlayer:SetPlayerInfo(playerInfo)
    commonlib.partialcopy(self.playerInfo, playerInfo);
    self:SetUpdatePlayerInfo(true);
end

-- 获取玩家信息
function EntityMainPlayer:GetPlayerInfo()
    return self.playerInfo;
end
-- 实体玩家是否在家
function EntityMainPlayer:IsOnline()
    return self.playerInfo.state == "online";
end

-- 获取玩家同步信息的频率  33 = 1s   tick = 30fps
-- 该值决定同步包的间隔时长
function EntityMainPlayer:GetMotionSyncTickCount()
    return IsDevEnv and 1 or 30;  -- 多久发一次同步包  1 = 30ms 本地帧频率
end

-- 获取玩家位置同步的帧距离, 移动多长距离记为1帧, 或理解为小于该值没有移动
-- 该值决定单次同步帧的数量, 若为0, 不丢帧, 若为无穷大则丢弃两次同步间的中间帧, 若指定值, 则同步指定间隔的关键帧
function EntityMainPlayer:GetMotionMinDistance()
    return 0.01;   -- 为零玩家一直处于运动状态  若此是频率为1, 则帧同步同本地完全一致
end

-- Send updated motion and position information to the server
function EntityMainPlayer:SendMotionUpdates()
    if(not self:GetInnerObject() or not self:IsNearbyChunkLoaded()) then return end
    -- 设置当前动画ID
	self:SetAnimId(self:GetInnerObject():GetField("AnimID", 0));
    self.motionUpdateTickCount = self.motionUpdateTickCount + 1;  -- tick 自增
    -- 获取模型验证模型的有效性
    local curMainAsset = self.dataWatcher:GetField(self.dataMainAsset);
    if(not AssetsWhiteList.IsInWhiteList(curMainAsset)) then self.dataWatcher:SetField(self.dataMainAsset, AssetsWhiteList.GetRandomFilename()) end

    local lastMoved, lastXYZ, curAnimId = self.lastMoved, self.lastXYZ, self:GetAnimId();
    local maxMoveDelayFrameCount = 30;
    local hasPlayerInfoChange = self:IsUpdatePlayerInfo();
    local hasMetaDataChange = self.dataWatcher:HasChanges();
    local hasHeadRotation = self.rotationHeadYaw ~= self.oldRotHeadYaw or self.rotationHeadPitch ~= self.oldRotHeadPitch;
    local hasRotation = self.facing ~= self.oldRotationYaw or self.rotationPitch ~= self.oldRotationPitch;
    local xyz = string.format("%.2f %.2f %.2f", self.x, self.y, self.z) 
    local hasMoved, curMoved = self.oldXYZ ~= xyz, self.lastXYZ ~= xyz;
    local moveDistance = math.max(math.abs(self.x - self.lastX), math.max(math.abs(self.y - self.lastY), math.abs(self.z - self.lastZ)));

    -- 备份当前位置
    self.lastMoved = curMoved;
    self.lastXYZ = xyz;
    self.lastX, self.lastY, self.lastZ = self.x, self.y, self.z;
    -- 开始或停止运动
    if (lastMoved ~= curMoved) then 
        if (curMoved) then
            -- 开始运动 重置tick
            self.motionUpdateTickCount = 1;
            self.lastMotionUpdateTickCount = 0;
            self.stopMotionUpdateTickCount = nil;    
            maxMotionUpdateTickCount = self:GetMotionSyncTickCount();
        else
            -- 停止运动
            self.stopMotionUpdateTickCount = self.motionUpdateTickCount;
        end
    end      

    local GetPacketPlayerEntityInfo = function()
        -- 构建包
        local packet = Packets.PacketPlayerEntityInfo:new():Init(nil, self.dataWatcher, false);
        -- 设置用户名
        packet.username = self:GetUserName();
        packet.entityId = self.entityId;
        packet.tick = self.motionUpdateTickCount - self.lastMotionUpdateTickCount;

        -- 保存tick状态
        self.lastMotionUpdateTickCount = self.motionUpdateTickCount;
        self.stopMotionUpdateTickCount = nil;

        if (self:IsUpdatePlayerInfo()) then
            packet.playerInfo = self:GetPlayerInfo();
            self:SetUpdatePlayerInfo(false);
        end

        if (hasMoved or hasRotation) then
            packet.x, packet.y, packet.z = self.x, self.y, self.z; 
            packet.bx, packet.by, packet.bz = self:GetBlockPos();
        end
        
        if (hasHeadRotation) then packet.facing, packet.pitch = self.facing, self.rotationPitch end 
        if (hasHeadRotation) then packet.headYaw, packet.headPitch = self.rotationHeadYaw, self.rotationHeadPitch end

        -- 记录上一个包的状态
        self.oldXYZ = xyz;
        self.oldRotationYaw = self.facing;
        self.oldRotationPitch = self.rotationPitch;
        self.oldRotHeadYaw = self.rotationHeadYaw;
        self.oldRotHeadPitch = self.rotationHeadPitch;

        return packet;
    end

    local isSync = self.stopMotionUpdateTickCount or (self.motionUpdateTickCount > maxMotionUpdateTickCount and (not self.motionPacketList:Empty() or  hasPlayerInfoChange or hasMetaDataChange or hasMoved or hasHeadRotation or hasRotation));
    -- 超过指定距离, 停止运动, 超过指定时间添加中间帧
    if (moveDistance > self:GetMotionMinDistance() or isSync) then
        self.motionPacketList:AddPacket(GetPacketPlayerEntityInfo());  -- 添加移动帧
    end

    if (not isSync) then return end
    
    -- 更新最大同步时间
    if (hasMoved) then              
        -- motionUpdateTickCount 为本次移动所需时间, 调整下次移动时间上限为本次时间-5*30ms, 可以低消150ms网络延迟, 客户端存在移动帧队列故可以下次时间比上次时间短
        -- maxMotionUpdateTickCount = math.max(math.min(self.motionUpdateTickCount, self:GetMotionSyncTickCount()) - 5, 1); 
        maxMotionUpdateTickCount = self:GetMotionSyncTickCount();                                                   
        -- maxMotionUpdateTickCount = self.motionUpdateTickCount;      -- 尽量保证下个数据包比上时间长， 因在在其它玩家世界自己人物慢一个节拍，避免上次动画未完成就播放本次动画 如果是强制更新, 则将tick频率调低  30fps  33 = 1s
    else                                                               -- 如果不动, 同步频率X2增长 原地操作降低更新频率 最大值为2min                                                                                                                          
        maxMotionUpdateTickCount =  maxMotionUpdateTickCount > (30 * 120) and maxMotionUpdateTickCount or (maxMotionUpdateTickCount + maxMotionUpdateTickCount);       -- 5 10 20 40 80 160 320 640
    end
  
    -- 发送帧序
    self:AddToSendQueue(self.motionPacketList);
    self.motionPacketList:CleanPacket();                 -- 清空运动包列表
    -- 重置计数器
    self.motionUpdateTickCount = 0; 
    self.lastMotionUpdateTickCount = 0;
end

-- @param chatmsg: ChatMessage or string. 
function EntityMainPlayer:SendChatMsg(chatmsg, chatdata)
    return false;
end

-- 是否可以触发压力
function EntityMainPlayer:doesEntityTriggerPressurePlate()
    return true;
end

-- 获取实体信息
function EntityMainPlayer:GetPacketPlayerEntityInfo()
    local packet = Packets.PacketPlayerEntityInfo:new():Init({entityId = self.entityId}, self.dataWatcher, true);
    packet.x, packet.y, packet.z = self.x, self.y, self.z; 
    packet.facing, packet.pitch = self.facing, self.rotationPitch;
    packet.headYaw, packet.headPitch = self.rotationHeadYaw, self.rotationHeadPitch;
    packet.bx, packet.by, packet.bz = self:GetBlockPos();
    packet.playerInfo = self:GetPlayerInfo();
    return packet;
end
