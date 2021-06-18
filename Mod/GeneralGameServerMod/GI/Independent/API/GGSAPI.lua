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
}

local function __G_Connect__(opts)
    GIGeneralGameClient:LoadWorld(opts);
end
setfenv(__G_Connect__, __G__);

local function __G_Send__(to, action, data)
    local dataHandler = GIGeneralGameClient:GetClientDataHandler();
    if (not dataHandler) then return end
    DATA.__to__, DATA.__action__, DATA.__data__ = to, action, data;
    dataHandler:SendData(DATA);
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
    __code_env__.RegisterEventCallBack("__GGS_CONNECT__", callback);
    __G_Connect__({username = username});
end

local function GGS_Send(data)
    __G_Send__(nil, nil, data);
end

local function GGS_SendTo(to, data)
    __G_Send__(to, nil, data);
end

local function GGS_SendUserData(data)
    __G_Send__(nil, "SetUserData", data);
end

local function GGS_RecvUserData(callback)
    __code_env__.RegisterEventCallBack("__GGS_USER_DATA__", callback);
end

local function GGS_PullAllUserData()
    __G_Send__(nil, "PullWorldData");
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

local function SetUserData(username, data)
    __all_user_data__[username] = __all_user_data__[username] or {};
    commonlib.partialcopy(__all_user_data__[username], data);
end

local function RecvDataCallBack(data)
    local __action__, __username__, __data__ = data.__action__, data.__username__, data.__data__;

    if (__action__ == "PullWorldData") then
        for username, userdata in pairs(__data__) do
            userdata.__username__ = key;
            __code_env__.TriggerEventCallBack("__GGS_USER_DATA__", userdata);
        end
    elseif (action == "SetUserData") then
        __data__.__username__ = __username__;
        __code_env__.TriggerEventCallBack("__GGS_USER_DATA__", __data__);
        return ;
    end

    __data__.__username__ = __username__;
    __code_env__.TriggerEventCallBack("__GGS_DATA__", __data__);
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
        CodeEnv.GGS_SendTo = GGS_SendTo;
        CodeEnv.GGS_Recv = GGS_Recv;
        CodeEnv.GGS_Disconnect = GGS_Disconnect;
        CodeEnv.GGS_SetUserData = GGS_SetUserData;

        CodeEnv.GGS_SendUserData = GGS_SendUserData;
        CodeEnv.GGS_RecvUserData = GGS_RecvUserData;
        CodeEnv.GGS_PullAllUserData = GGS_PullAllUserData;
        
        CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() __G_Disconnect__() end);
    end
})
