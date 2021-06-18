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

function GIServerDataHandler:RecvData(data)
    -- GGS.INFO(data);
    -- print(self:GetCurrentPlayer())
    if (data.__to__) then return self:SendDataToPlayer(data, data.__to__) end
    self:SendDataToAllPlayer(data);
end

function GIServerDataHandler:GetHandlerName()
    return "__GI__";
end

