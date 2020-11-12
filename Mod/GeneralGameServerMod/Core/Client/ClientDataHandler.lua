--[[
Title: DataHandler
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/ClientDataHandler.lua");
local ClientDataHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.ClientDataHandler");
-------------------------------------------------------
]]

local ClientDataHandler = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.ClientDataHandler"));

ClientDataHandler:Property("NetHandler");

function ClientDataHandler:GetConnection()
    return self:GetNetHandler().connection;
end

function ClientDataHandler:Init(netHandler)
    self:SetNetHandler(netHandler);
    return self;
end

function ClientDataHandler:SendData(data)
    self:GetConnection():SendData(data);
end

-- 重载此函数 处理收到网络数据
function ClientDataHandler:RecvData(data)
    -- GGS.INFO("ClientDataHandler", data);
end
