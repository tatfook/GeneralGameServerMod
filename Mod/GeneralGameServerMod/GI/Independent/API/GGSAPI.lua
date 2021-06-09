--[[
Title: GGSAPI
Author(s):  wxa
Date: 2021-06-01
Desc: API 模板文件
use the lib:
------------------------------------------------------------
local GGSAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/GGSAPI.lua");
------------------------------------------------------------
]]

local GIGeneralGameClient = NPL.load("../../Game/GGS/GIGeneralGameClient.lua", IsDevEnv);

local GGSAPI = NPL.export()
local __G__ = _G;
local __code_env__ = nil;


local function __G_Connect__(opts)
    GIGeneralGameClient:LoadWorld(opts);
end
setfenv(__G_Connect__, __G__);

local function __G_Send__(data)
    local dataHandler = GIGeneralGameClient:GetClientDataHandler();
    if (not dataHandler) then return end
    dataHandler:SendData(data);
end
setfenv(__G_Send__, __G__);

local function __G_Disconnect__()
    GIGeneralGameClient:OnWorldUnloaded();
end
setfenv(__G_Disconnect__, __G__);


local function GGS_GetPlayerManager()
    local world = GIGeneralGameClient:GetWorld();
    return world and world:GetPlayerManager();
end

local function GGS_GetMainPlayer()
    local playerManager = GGS_GetPlayerManager();
    return playerManager and playerManager:GetMainPlayer();
end

local function GGS_GetPlayer(username)
    local playerManager = GGS_GetPlayerManager();
    if (not playerManager) then return end
    if (not username) then return playerManager:GetMainPlayer()() end
    return playerManager:GetPlayerByUserName(username);
end

local function GGS_Connect(callback)
    local username = __code_env__.GetUserName();
    __code_env__.RegisterEventCallBack("GGS_CONNECT", callback);
    __G_Connect__({username = username});
end

local function GGS_Send(data)
    __G_Send__(data);
end

local function GGS_Recv(callback)
    __code_env__.RegisterEventCallBack("GGS_DATA", callback);
end

local function GGS_Disconnect(callback)
    if (type(callback) == "function") then
        __code_env__.RegisterEventCallBack("GGS_DISCONNECT", callback);
    else 
        __G_Disconnect__();
    end
end

local function RecvDataCallBack(...)
    __code_env__.TriggerEventCallBack("GGS_DATA", ...);
end

local function ConnectionCallBack(...)
    __code_env__.TriggerEventCallBack("GGS_CONNECT", ...);
end

local function DisconnectionCallBack(...)
    __code_env__.TriggerEventCallBack("GGS_DISCONNECT", ...);
end

GIGeneralGameClient:GetClientDataHandlerClass():SetRecvDataCallBack(RecvDataCallBack);
GIGeneralGameClient:SetConnectionCallBack(ConnectionCallBack);
GIGeneralGameClient:SetDisconnectionCallBack(DisconnectionCallBack);

setmetatable(GGSAPI, {
    __call = function(_, CodeEnv)
        __code_env__ = CodeEnv;

        CodeEnv.GGS_Connect = GGS_Connect;
        CodeEnv.GGS_Send = GGS_Send;
        CodeEnv.GGS_Recv = GGS_Recv;
        CodeEnv.GGS_Disconnect = GGS_Disconnect;
        CodeEnv.GGS_GetPlayer = GGS_GetPlayer;
        
        CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() __G_Disconnect__() end);
    end
})
