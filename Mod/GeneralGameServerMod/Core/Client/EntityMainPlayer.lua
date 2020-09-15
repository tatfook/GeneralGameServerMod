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
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local EntityMainPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPClient"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer"));
local AssetsWhiteList = NPL.load("./AssetsWhiteList.lua");

local moduleName = "Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer";
local maxMotionUpdateTickCount = 33;

EntityMainPlayer:Property("UpdatePlayerInfo", false, "IsUpdatePlayerInfo");

-- 构造函数
function EntityMainPlayer:ctor()
    self.playerInfo = {};
    self.oldXYZ = "";
    self.motionAnimId = 0;
    self.lastMoved = false;
    self.lastXYZ = "";
    self.motionUpdateTickCount = 0;
end

-- 初始化函数
function EntityMainPlayer:init(world, netHandler, entityId)
    EntityMainPlayer._super.init(self, world, netHandler, entityId);
    self:SetSkipPicking(not self:IsCanClick());
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
function EntityMainPlayer:GetMotionSyncTickCount()
    return 30;
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
    
    -- 备份当前位置
    self.lastMoved = curMoved;
    self.lastXYZ = xyz;
    -- 开始或停止运动
    if (lastMoved ~= curMoved) then 
        if (curMoved) then
            -- 开始运动 重置tick
            self.motionUpdateTickCount = 1;
            maxMotionUpdateTickCount = self:GetMotionSyncTickCount();
        else
            -- 停止运动
            self.stopMotionUpdateTickCount = self.motionUpdateTickCount;
        end
    end      
    -- 记录上次运动的动画ID
    if ((curAnimId == 4 or curAnimId == 5 or curAnimId == 37 or curAnimId == 41 or curAnimId == 42) and self.motionAnimId ~= curAnimId) then self.motionAnimId = curAnimId end

    -- 位置实时同步, 其它 hasMetaDataChange, hasHeadRotation, hasRotation 配合 Tick 同步
    local isSync = self.motionUpdateTickCount > maxMotionUpdateTickCount and (hasPlayerInfoChange or hasMetaDataChange or hasMoved or hasHeadRotation or hasRotation);
    if (not isSync) then return end
    
    if (hasMoved) then                                                                  
        maxMotionUpdateTickCount = self.motionUpdateTickCount;      -- 尽量保证下个数据包比上时间长， 因在在其它玩家世界自己人物慢一个节拍， 如果是强制更新, 则将tick频率调低  30fps  33 = 1s
    else                                                            -- 如果不动, 同步频率X2增长 原地操作降低更新频率 最大值为2min                                                                                                                          
        maxMotionUpdateTickCount =  maxMotionUpdateTickCount > (30 * 120) and maxMotionUpdateTickCount or (maxMotionUpdateTickCount + maxMotionUpdateTickCount);       -- 5 10 20 40 80 160 320 640
    end
    -- 构建包
    local packet = Packets.PacketPlayerEntityInfo:new():Init(nil, self.dataWatcher, false);
    -- 设置用户名
    packet.username = self:GetUserName();
    packet.entityId = self.entityId;
    packet.tick = self.stopMotionUpdateTickCount or self.motionUpdateTickCount;
    packet.motionAnimId = self.motionAnimId;

    self.stopMotionUpdateTickCount = nil;

    if (self:IsUpdatePlayerInfo()) then
        packet.playerInfo = self:GetPlayerInfo();
        self:SetUpdatePlayerInfo(false);
    end

    if (hasMoved or hasRotation) then
        packet.x, packet.y, packet.z = self.x, self.y, self.z; 
        packet.facing, packet.pitch = self.facing, self.rotationPitch;
        packet.bx, packet.by, packet.bz = self:GetBlockPos();
    end
    
    if (hasHeadRotation) then
        packet.headYaw, packet.headPitch = self.rotationHeadYaw, self.rotationHeadPitch;
    end
  
    self:AddToSendQueue(packet);
    -- 还原真正的动画ID
    self.oldXYZ = xyz;
    self.oldRotationYaw = self.facing;
    self.oldRotationPitch = self.rotationPitch;
    self.oldRotHeadYaw = self.rotationHeadYaw;
	self.oldRotHeadPitch = self.rotationHeadPitch;
    self.motionUpdateTickCount = 0; 
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
