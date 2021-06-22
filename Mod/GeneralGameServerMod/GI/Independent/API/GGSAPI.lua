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

local DATA = {
    __handler__ = "__GI__",
    __to__ = nil,
    __data__ = nil;
    __action__ = nil;
    __username__ = nil;  -- 数据包所属者
}


local function __G_Connect__(opts)
    GIGeneralGameClient:LoadWorld(opts);
end
setfenv(__G_Connect__, __G__);

local function __G_Send__(data, to, action)
    local dataHandler = GIGeneralGameClient:GetClientDataHandler();
    if (not dataHandler) then return end
    DATA.__to__, DATA.__action__, DATA.__data__, DATA.__username__ = to, action, data, __code_env__.GetUserName();
    dataHandler:SendData(DATA);
end
setfenv(__G_Send__, __G__);

local function __G_Disconnect__()
    GIGeneralGameClient:OnWorldUnloaded();
end
setfenv(__G_Disconnect__, __G__);

-- local function GGS_GetPlayerManager()
--     local world = GIGeneralGameClient:GetWorld();
--     return world and world:GetPlayerManager();
-- end

-- local function GGS_GetMainPlayer()
--     local playerManager = GGS_GetPlayerManager();
--     return playerManager and playerManager:GetMainPlayer();
-- end

-- local function GGS_GetPlayer(username)
--     local playerManager = GGS_GetPlayerManager();
--     if (not playerManager) then return end
--     if (not username) then return playerManager:GetMainPlayer()() end
--     return playerManager:GetPlayerByUserName(username);
-- end

local function GGS_Connect(callback)
    local username = __code_env__.GetUserName();
    __code_env__.RegisterEventCallBack("__GGS_CONNECT__", callback);
    __G_Connect__({username = username});
end

local function GGS_Send(data, to, action)
    __G_Send__(data, to, action);
end

local function GGS_Recv(callback)
    __code_env__.RegisterEventCallBack("__GGS_DATA__", callback);
end

local function GGS_Disconnect(callback)
    if (type(callback) == "function") then
        __code_env__.RegisterEventCallBack("__GGS_DISCONNECT__", callback);
    else 
        __G_Disconnect__();
    end
end

local function RecvDataCallBack(data)
    __code_env__.TriggerEventCallBack("__GGS_DATA__", data);
end

local function ConnectionCallBack(...)
    __code_env__.TriggerEventCallBack("__GGS_CONNECT__", ...);
end

local function DisconnectionCallBack(...)
    __code_env__.TriggerEventCallBack("__GGS_DISCONNECT__", ...);
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
        
        CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() __G_Disconnect__() end);
    end
})
