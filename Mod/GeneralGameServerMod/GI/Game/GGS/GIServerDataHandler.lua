--[[
Title: GIServerDataHandler
Author(s): wxa
Date: 2020/7/9
Desc: 主玩家实体类, 主实现主玩家相关操作
use the lib:
------------------------------------------------------------
local GIServerDataHandler = NPL.load("Mod/GeneralGameServerMod/GI/Game/GGS/GIServerDataHandler.lua");
-------------------------------------------------------
]]

local ServerDataHandler = NPL.load("Mod/GeneralGameServerMod/Core/Server/ServerDataHandler.lua");
local GIServerDataHandler = commonlib.inherit(ServerDataHandler, NPL.export());

local __data__ = {};
local ONE_DAY = 24 * 3600 * 1000;

local __world_keys__ = {};
local function DeleteExpiredData()
    local index = 0;
    local curtime = ParaGlobal.timeGetTime();
    for worldKey, worldData in pairs(__data__) do
        if (worldData.__expire_time__ < curtime) then
            index = index + 1;
            __world_keys__[index] = worldKey;
        end
    end
    -- 删除过期的世界数据
    for i = 1, index do
        __data__[__world_keys__[i]] = nil;
    end
end

function GIServerDataHandler:GetWorld()
    return self:GetNetHandler():GetWorld();
end

function GIServerDataHandler:GetUserName()
    return self:GetCurrentPlayer():GetUserName();
end

function GIServerDataHandler:GetWorldData()
    local workKey = self:GetWorld():GetWorldKey();
    __data__[workKey] = __data__[workKey] or {};
    local worldData = __data__[workKey];
    worldData.__expire_time__ = ParaGlobal.timeGetTime() + ONE_DAY;
    return __data__[workKey];
end

function GIServerDataHandler:GetUserData()
    local worldData = self:GetWorldData();
    local username = self:GetUserName();
    worldData.__users_data__ = worldData.__users_data__ or {};
    local users_data = worldData.__users_data__;
    users_data[username] = users_data[username] or {};
    return users_data[username];
end

function GIServerDataHandler:GetAllUserData()
    return self:GetWorldData().__users_data__;
end

function GIServerDataHandler:SetUserData(data)
    local userdata = self:GetUserData();
    commonlib.partialcopy(userdata, data.__data__);
end

function GIServerDataHandler:RecvData(data)
    data.__username__ = self:GetUserName();
    
    DeleteExpiredData();

    -- GGS.INFO(data);
    -- print(self:GetCurrentPlayer())
    -- local action = data.__action__;
    if (action == "SetUserData") then
        self:SetUserData(data);
    elseif (action == "PullAllUserData") then
        data.__data__ = self:GetAllUserData();
        return self:SendDataToPlayer(data, self:GetCurrentPlayer());
    end

    if (data.__to__) then return self:SendDataToPlayer(data, data.__to__) end

    self:SendDataToAllPlayer(data);
end

function GIServerDataHandler:GetHandlerName()
    return "__GI__";
end


-- TODO
-- 增加数据缓存, 还是存在客户端
