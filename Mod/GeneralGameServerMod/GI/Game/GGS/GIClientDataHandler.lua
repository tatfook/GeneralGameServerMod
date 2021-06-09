--[[
Title: GIClientDataHandler
Author(s): wxa
Date: 2020/7/9
Desc: 主玩家实体类, 主实现主玩家相关操作
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/GI/Game/GGS/GIClientDataHandler.lua");
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Client/ClientDataHandler.lua");

local GIClientDataHandler = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.ClientDataHandler"), NPL.export());

GIClientDataHandler:Property("RecvDataCallBack"); -- 接收数据回调

function GIClientDataHandler:RecvData(data)
    local callback = self:GetRecvDataCallBack();
    if (type(callback) == "function") then callback(data) end
end
