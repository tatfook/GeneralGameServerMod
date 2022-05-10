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
ClientDataHandler:Property("RecvDataCallBack");   -- 接收数据回调

function ClientDataHandler:GetConnection()
    return self:GetNetHandler().connection;
end

function ClientDataHandler:Init(netHandler)
    self:SetNetHandler(netHandler);
    return self;
end

function ClientDataHandler:SendData(data)
    local connection = self:GetConnection();
    if (not connection) then return end 
    connection:SendData(data);
end

-- 重载此函数 处理收到网络数据
function ClientDataHandler:RecvData(data)
    -- GGS.INFO("ClientDataHandler", data);
    local callback = self:GetRecvDataCallBack();
    if (type(callback) == "function") then callback(data) end
end

function ClientDataHandler:OnLogin()
end