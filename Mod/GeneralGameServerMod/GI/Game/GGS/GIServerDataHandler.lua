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

function GIServerDataHandler:GetShareData()
    local worldData = self:GetWorldData();
    worldData.__share_data__ = worldData.__share_data__ or {};
    return worldData.__share_data__;
end

function GIServerDataHandler:SetShareData(data)
    local shareData = self:GetShareData();
    commonlib.partialcopy(shareData, data);
end

function GIServerDataHandler:GetAllUserData()
    local world_data = self:GetWorldData();
    world_data.__all_user_data__ = world_data.__all_user_data__ or {};
    return world_data.__all_user_data__;
end

function GIServerDataHandler:GetUserData()
    local username = self:GetUserName();
    local __all_user_data__ = self:GetAllUserData();
    __all_user_data__[username] = __all_user_data__[username] or {};
    return __all_user_data__[username];
end

function GIServerDataHandler:HandleUserConnect()
    local userdata = self:GetUserData();
    userdata.__connect_at__ = ParaGlobal.timeGetTime();
    userdata.__is_online__ = true;

    self:SendDataToPlayer({
        __action__ = "__response_connect__",
        __data__ = self:GetWorldData(),
    }, self:GetCurrentPlayer());
end

function GIServerDataHandler:HandlePushShareData(data)
    local shareData = self:GetShareData();
    commonlib.partialcopy(shareData, data.__data__);
    self:SendDataToAllPlayer(data);
end

function GIServerDataHandler:HandlePushUserData(data)
    local userdata = self:GetUserData();
    commonlib.partialcopy(userdata, data.__data__);
    data.__username__ = self:GetUserName();
    self:SendDataToAllPlayer(data);
end

function GIServerDataHandler:RecvData(data)
    -- 过期数据监测
    DeleteExpiredData();   

    local __action__, __to__ = data.__action__, data.__to__;
    if (__action__ == "__request_connect__") then
        return self:HandleUserConnect();
    elseif (__action__ == "__push_share_data__") then
        return self:HandlePushShareData(data);
    elseif (__action__ == "__push_user_data__") then
        return self:HandlePushUserData(data);
    elseif (__to__) then
        self:SendDataToPlayer(data, data.__to__);
    else
        self:SendDataToAllPlayer(data);
    end
end

function GIServerDataHandler:OnDisconnect()
    local userdata = self:GetUserData();
    userdata.__is_online__ = false;
end

function GIServerDataHandler:GetHandlerName()
    return "__GI__";
end


-- TODO
-- 增加数据缓存, 还是存在客户端
