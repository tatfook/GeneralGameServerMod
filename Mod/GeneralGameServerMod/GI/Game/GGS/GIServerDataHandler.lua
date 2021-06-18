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
    worldData.__expire_time__ = Pa
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

function GIServerDataHandler:SetUserData(data)
    local userdata = self:GetUserData();
    commonlib.partialcopy(userdata, data.data);
end

function GIServerDataHandler:RecvData(data)
    -- GGS.INFO(data);
    -- print(self:GetCurrentPlayer())
    -- local action = data.__action__;
    -- if (action == "SetUserData") then
    --     return self:SetUserData(data);
    -- end

    if (data.__to__) then return self:SendDataToPlayer(data, data.__to__) end

    self:SendDataToAllPlayer(data);
end

function GIServerDataHandler:GetHandlerName()
    return "__GI__";
end


-- TODO
-- 增加数据缓存, 还是存在客户端
