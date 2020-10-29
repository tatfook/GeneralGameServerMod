--[[
Title: Track
Author(s): wxa
Date: 2020/6/10
Desc: 世界用户移动轨迹
use the lib: 
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/Track.lua");
local Track = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Track");
-------------------------------------------------------
]]

local Track = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Track"));

Track:Property("World");

local AreaSize = 10;
local AreaMaxPositionCount = 5;
local MaxPositionCount = 2000;
local Area = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});

local function GetBlockIndex(bx, by, bz)
    return by*900000000+bx*30000+bz;
end

function Area:ctor()
    self.positionCount = 0;
    self.visitCount = 0;
end

function Area:GetPositionCount()
    return self.positionCount;
end

function Area:AddPositionCount(count)
    self.positionCount = self.positionCount + (count or 1);
end

function Area:AddVisitCount(count)
    self.visitCount = self.visitCount + (count or 1);
end

function Area:IsFullPosition()
    return self.positionCount >= AreaMaxPositionCount;
end

function Track:ctor()
    self.areas = {};                     -- 区域
    self.positions = {};                 -- 位置
    self.positionPlayer = {};            -- 位置对应的玩家
    self.positionCount = 0;              -- 位置的数量
    self.unpositionPlayerList = {};      -- 未分配位置的玩家列表
end

function Track:Init(world)
    self:SetWorld(world);

    return self;
end

function Track:GetAreaIndex(bx, by, bz)
    local x = math.floor(bx / AreaSize);
    local y = math.floor(by / AreaSize);
    local z = math.floor(bz / AreaSize);
    return y*900000000+x*30000+z;
end

function Track:GetArea(bx, by, bz)
    local index = self:GetAreaIndex(bx, by, bz);
    self.areas[index] = self.areas[index] or Area:new();
    return self.areas[index];
end

function Track:AddPosition(bx, by, bz, x, y, z)
    if (self.positionCount > MaxPositionCount) then return end

    local area = self:GetArea(bx, by, bz);
    if (area:IsFullPosition()) then return area:AddVisitCount() end

    local blockIndex = GetBlockIndex(bx, by, bz);
    self.positionCount = self.positionCount + 1;
    self.positions[blockIndex] = {x = x, y = y, z = z, bx = bx, by = by, bz = bz, blockIndex = blockIndex, id = self.positionCount};

    area:AddPositionCount();

    if (#(self.unpositionPlayerList) ~= 0) then
        local player = self.unpositionPlayerList[1];
        table.remove(self.unpositionPlayerList, 1);
        self:AddOfflinePlayer(player);
    end
end

function Track:GetAvailablePos()
    for index, pos in pairs(self.positions) do
        if (not self.positionPlayer[index]) then 
            return pos, index;
        end
    end
end

function Track:AddOfflinePlayer(offlinePlayer)
    local pos, index = self:GetAvailablePos();
    if (not pos) then return table.insert(self.unpositionPlayerList, offlinePlayer) end
    self.positionPlayer[index] = offlinePlayer;
    offlinePlayer:SetPos(pos.x, pos.y, pos.z);
    offlinePlayer:SetBlockPos(pos.bx, pos.by, pos.bz);
    -- 可以主动再通知在线玩家, 离线玩家位置更新
end

function Track:RemoveOfflinePlayer(offlinePlayer)
    for index, player in pairs(self.positionPlayer) do
        if (player == offlinePlayer) then
            self.positionPlayer[index] = nil;
            break;
        end
    end
    for index, player in ipairs(self.unpositionPlayerList) do
        if (player == offlinePlayer) then
            table.remove(self.unpositionPlayerList, index);
            break;
        end
    end
end
