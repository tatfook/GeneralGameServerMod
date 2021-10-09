
--[[
Title: World
Author(s):  wxa
Date: 2021-06-30
Desc: 网络API
use the lib:
------------------------------------------------------------
local World = NPL.load("Mod/GeneralGameServerMod/Server/Net/World.lua");
------------------------------------------------------------
]]

local ThreadHelper = NPL.load("Mod/GeneralGameServerMod/CommonLib/ThreadHelper.lua");
local World = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local __all_world__ = {};

World:Property("MaxClientCount", 100);
World:Property("ClientCount", 0);
World:Property("WorldKey");
World:Property("WorldId");
World:Property("WorldName");

-- 生成世界KEY
local function GenerateWorldKey(worldId, worldName, no)
    return string.format("%s_%s_%s", worldId, worldName or "", no or "");
end

-- 获取世界KEY
local function GetWorldKey(worldId, worldName, no)        
    local worldKey = GenerateWorldKey(worldId, worldName, no);
    local world = __all_world__[worldKey];
    if (not world or world:GetClientCount() < world:GetMaxClientCount()) then return worldKey end 
    return GetWorldKey(worldId, worldName, (no or 0) + 1);
end

-- 获取指定世界
function World:GetWorld(worldId, worldName, worldKey, isNewNoExist)
    if (not worldKey or not string.find(worldKey, GenerateWorldKey(worldId, worldName), 1, true)) then worldKey = GetWorldKey(worldId, worldName) end
    if (__all_world__[worldKey]) then return __all_world__[worldKey] end 
    if (not isNewNoExist) then return end
    return World:new():Init(worldId, worldName, worldKey);
end

function World:ctor()
    self.__all_player__ = {};
    self.__all_user_data__ = {};
    self.__share_data__ = {};
end

function World:Init(worldId, worldName, worldKey)
    self:SetWorldId(worldId);
    self:SetWorldName(worldName);
    self:SetWorldKey(worldKey);

    __all_world__[self:GetWorldKey()] = self;

    return self;
end

function World:UploadWorldInfo()
    local worldKey = self:GetWorldKey();
    ThreadHelper:SendMsgToMainThread({
        __worlds__ = {
            [worldKey]  = {
                worldId = self:GetWorldId(),
                worldName = self:GetWorldName(),
                maxClientCount = self:GetMaxClientCount(),
                clientCount = self:GetPlayerCount(),
            }
        }
    });
end

function World:AddPlayer(player)
    self.__all_player__[player:GetUserName()] = player;
    self:UploadWorldInfo();
end

function World:RemovePlayer(player)
    self.__all_player__[player:GetUserName()] = nil;
    self:UploadWorldInfo();
end

function World:GetPlayer(username)
    return self.__all_player__[username];
end

function World:GetAllPlayer()
    return self.__all_player__;
end

function World:GetPlayerCount()
    local count = 0;
    for _, player in pairs(self.__all_player__) do count = count + 1 end
    return count;
end

function World:GetUserData(username)
    self.__all_user_data__[username] = self.__all_user_data__[username] or {};
    return self.__all_user_data__[username];
end

function World:SetUserData(username, data)
    commonlib.partialcopy(self:GetUserData(username), data);
end

function World:GetAllUserData()
    return self.__all_user_data__;
end

function World:GetShareData()
    return self.__share_data__;
end

function World:SetShareData(data)
    commonlib.partialcopy(self:GetShareData(), data);
end

function World:GetAllEntityData()
    local __all_entity_data__ = {};
    for username, player in pairs(self.__all_player__) do
        __all_entity_data__[username] = player:GetEntityData();
    end
    return __all_entity_data__;
end

function World:SendToAllPlayer(action, data, excludePlayer)
    for _, player in pairs(self.__all_player__) do
        if (player ~= excludePlayer) then
            player:Send(action, data);
        end
    end
end

function World:SendToPlayer(username, action, data)
    local player = self:GetPlayer(username);
    if (not player) then return end 
    player:Send(action, data);
end

function World:Lock(username)
    -- 已上锁则返回失败
    if (self.__lock_username__ and username and self.__lock_username__ ~= username) then return false end 
    self.__lock_username__ = username;
    return true;
end

function World:Unlock(username)
    -- username = nil 强制解锁
    if (self.__lock_username__ and self.__lock_username__ ~= username) then return false end 
    self.__lock_username__ = nil;
    return true;
end
