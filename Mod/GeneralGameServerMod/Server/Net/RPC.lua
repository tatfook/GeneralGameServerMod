--[[
Title: Handler
Author(s):  wxa
Date: 2021-06-30
Desc: 网络API
use the lib:
------------------------------------------------------------
local RPC = NPL.load("Mod/GeneralGameServerMod/Server/Net/RPC.lua");
------------------------------------------------------------
]]

local RPCVirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPCVirtualConnection.lua");
local Player = NPL.load("./Player.lua");
local World = NPL.load("./World.lua");

local RPC = commonlib.inherit(RPCVirtualConnection, NPL.export());
RPCVirtualConnection:Property("LocalNeuronFile", "Mod/GeneralGameServerMod/Server/Net/RPC.lua");        -- 本地处理文件

local __all_rpc__ = {};

RPC:Property("Player");
RPC:Property("World");

-- 登录
function RPC:Login(data)
    local username, worldId, worldName, worldKey, maxClientCount = data.username, data.worldId, data.worldName, data.worldKey, data.maxClientCount;
    local player = Player:GetPlayer(username, true);
    local world = World:GetWorld(worldId, worldName, worldKey, true);
    if (maxClientCount) then world:SetMaxClientCount(maxClientCount) end
    local playerWorld = player:GetWorld();
    if (playerWorld and playerWorld ~= world) then playerWorld:RemovePlayer(player) end
    world:AddPlayer(player);

    self:SetWorld(world);
    self:SetPlayer(player);
    player:SetConnection(self);
    __all_rpc__[username] = self;

    return {
        __world_key__ = world:GetWorldKey();
        __all_user_data__ = world:GetAllUserData(),
        __share_data__ = world:GetShareData(),
        __all_entity_data__ = world:GetAllEntityData(),
    }
end

-- 连接是否有效
function RPC:IsValid()
    if (self:GetPlayer() and self:GetWorld()) then return true end

    self:Emit("ReLogin", "无效连接"); -- 调用重新登录

    return false;
end

-- 设置用户数据
function RPC:SetUserData(userdata)
    local username = self:GetPlayer():GetUserName();
    userdata.__username__ = username;
    self:GetWorld():SetUserData(username, userdata);
    self:GetWorld():SendToAllPlayer("SetUserData", userdata, self:GetPlayer());
end

-- 设置共享数据
function RPC:SetShareData(sharedata)
    if (not self:IsValid()) then return end 
    self:GetWorld():SetShareData(sharedata);
    self:GetWorld():SendToAllPlayer("SetShareData", sharedata, self:GetPlayer());
end

-- 广播给指定用户
function RPC:BroadcastTo(data)
    if (not self:IsValid()) then return end 
    self:GetWorld():SendToPlayer(data.username, "Broadcast", data.data);
end

-- 转发广播消息
function RPC:Broadcast(data)
    if (not self:IsValid()) then return end 
    self:GetWorld():SendToAllPlayer("Broadcast", data, self:GetPlayer());
end

-- 链接断开
function RPC:HandleDisconnected()
    self:HandleClosed();
end

-- 链接关闭
function RPC:HandleClosed()
    if (not self:IsValid()) then return end 
    local username = self:GetPlayer():GetUserName();
    __all_rpc__[username] = nil;
    self:GetWorld():SendToAllPlayer("ConnectClosed", self:GetPlayer():GetUserName(), nil);
end

-- 处理未知消息
function RPC:HandleMsg(msg)
    RPC._super.HandleMsg(self, msg);
end

NPL.this(function()
    RPC:OnActivate(msg);
end);