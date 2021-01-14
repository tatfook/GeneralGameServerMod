--[[
Title: ServerDataHandler
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
local ServerDataHandler = NPL.load("Mod/GeneralGameServerMod/Core/Server/ServerDataHandler.lua");
-------------------------------------------------------
]]
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local ServerDataHandler = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ServerDataHandler:Property("NetHandler");

function ServerDataHandler:Init(netHandler)
    self:SetNetHandler(netHandler);
    return self;
end

function ServerDataHandler:GetConnection()
    return self:GetNetHandler();
end

function ServerDataHandler:GetDataPacket(data)
    return Packets.PacketGeneral:GetDataPacket(data);
end

-- 获取当前玩家
function ServerDataHandler:GetPlayer()
    return self:GetNetHandler():GetPlayer();
end

-- 发送数据给当前玩家
function ServerDataHandler:SendData(data)
    self:GetConnection():SendData(data);
end

-- 发送数据给所有玩家
function ServerDataHandler:SendDataToAllPlayer(data, bIncludeSelf)
    self:GetNetHandler():GetPlayerManager():SendPacketToAllPlayers(self:GetDataPacket(data), if_else(bIncludeSelf, nil, self:GetPlayer()), nil, false);
end

-- 重载此函数 处理收到网络数据
function ServerDataHandler:RecvData(data)
   
end


