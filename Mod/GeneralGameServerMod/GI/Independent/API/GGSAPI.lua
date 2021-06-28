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

NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");

local GIGeneralGameClient = NPL.load("../../Game/GGS/GIGeneralGameClient.lua", IsDevEnv);
local EventEmitter = NPL.load("../../Game/Event/EventEmitter.lua");

local GGSAPI = NPL.export()
local __G__ = _G;
local __event_emitter__ = EventEmitter:new();

local DATA = {
    __handler__ = "__GI__",
    __to__ = nil,
    __data__ = nil;
    __action__ = nil;
    __username__ = nil;  -- 数据包所属者
}

local EventType = {
    __GGS_DATA__ = "__GGS_DATA__",
    __GGS_CONNECT__ = "__GGS_CONNECT__",
    __GGS_DISCONNECT__ = "__GGS_DISCONNECT__",
}
local function RecvDataCallBack(...)
    __event_emitter__:TriggerEventCallBack(EventType.__GGS_DATA__, ...);
end

local function ConnectionCallBack(...)
    __event_emitter__:TriggerEventCallBack(EventType.__GGS_CONNECT__, ...);
end

local function DisconnectionCallBack(...)
    __event_emitter__:TriggerEventCallBack(EventType.__GGS_DISCONNECT__, ...);
end

GIGeneralGameClient:GetClientDataHandlerClass():SetRecvDataCallBack(RecvDataCallBack);
GIGeneralGameClient:SetConnectionCallBack(ConnectionCallBack);
GIGeneralGameClient:SetDisconnectionCallBack(DisconnectionCallBack);

AppGeneralGameClient:GetClientDataHandlerClass():SetRecvDataCallBack(RecvDataCallBack);
AppGeneralGameClient:SetConnectionCallBack(ConnectionCallBack);
AppGeneralGameClient:SetDisconnectionCallBack(DisconnectionCallBack);

local function __G_Connect__(__client__, opts)
    -- 所有独立沙盒公用GGS连接
    if (__client__:IsLogin()) then return ConnectionCallBack() end
    -- 未连接进行连接
    __client__:LoadWorld(opts);
end
setfenv(__G_Connect__, __G__);

local function __G_Send__(__client__, data, to, action, username)
    local dataHandler = __client__:GetClientDataHandler();
    if (not dataHandler) then return end
    DATA.__to__, DATA.__action__, DATA.__data__, DATA.__username__ = to, action, data, username;
    dataHandler:SendData(DATA);
end
setfenv(__G_Send__, __G__);

local function __G_Disconnect__(__client__)
    __client__:OnWorldUnloaded();
end
setfenv(__G_Disconnect__, __G__);

local function GGS_GetPlayerManager(__code_env__)
    local world = __code_env__.__ggs_client__:GetWorld();
    return world and world:GetPlayerManager();
end

local function GGS_GetMainPlayer(__code_env__)
    local playerManager = GGS_GetPlayerManager(__code_env__);
    return playerManager and playerManager:GetMainPlayer();
end

local function GGS_GetPlayer(__code_env__, username)
    local playerManager = GGS_GetPlayerManager(__code_env__);
    if (not playerManager) then return end
    if (not username or username == __code_env__.GetUserName()) then return playerManager:GetMainPlayer() end
    return playerManager:GetPlayerByUserName(username);
end

local function GGS_Connect(__code_env__, callback)
    local username = __code_env__.GetUserName();
    __code_env__.RegisterEventCallBack(EventType.__GGS_CONNECT__, callback);
    __G_Connect__(__code_env__.__ggs_client__, {username = username});
end

local function GGS_Send(__code_env__, data, to, action)
    __G_Send__(__code_env__.__ggs_client__, data, to, action, __code_env__.GetUserName());
end

local function GGS_Recv(__code_env__, callback)
    __code_env__.RegisterEventCallBack(EventType.__GGS_DATA__, callback);
end

local function GGS_Disconnect(__code_env__, callback)
    if (type(callback) == "function") then
        __code_env__.RegisterEventCallBack(EventType.__GGS_DISCONNECT__, callback);
    else 
        __G_Disconnect__(__code_env__.__ggs_client__);
    end
end

setmetatable(GGSAPI, {
    __call = function(_, CodeEnv)
        local function GGS_RecvDataCallBack(...)
            CodeEnv.TriggerEventCallBack(EventType.__GGS_DATA__, ...);
        end
        
        local function GGS_ConnectionCallBack(...)
            CodeEnv.TriggerEventCallBack(EventType.__GGS_CONNECT__, ...);
        end
        
        local function GGS_DisconnectionCallBack(...)
            CodeEnv.TriggerEventCallBack(EventType.__GGS_DISCONNECT__, ...);
        end

        CodeEnv.__ggs_client__ = AppGeneralGameClient;  -- 默认共享外部链接
        CodeEnv.GGS_Independent = function() CodeEnv.__ggs_client__ = GIGeneralGameClient end
        CodeEnv.GGS_Connect = function(...) return GGS_Connect(CodeEnv, ...) end
        CodeEnv.GGS_Send = function(...) return GGS_Send(CodeEnv, ...) end
        CodeEnv.GGS_Recv = function(...) return GGS_Recv(CodeEnv, ...) end
        CodeEnv.GGS_Disconnect = function(...) return GGS_Disconnect(CodeEnv, ...) end
        CodeEnv.GGS_GetPlayer = function(...) return GGS_GetPlayer(CodeEnv, ...) end
        
        __event_emitter__:RegisterEventCallBack(EventType.__GGS_DATA__, GGS_RecvDataCallBack, CodeEnv);
        __event_emitter__:RegisterEventCallBack(EventType.__GGS_CONNECT__, GGS_ConnectionCallBack, CodeEnv);
        __event_emitter__:RegisterEventCallBack(EventType.__GGS_DISCONNECT__, GGS_DisconnectionCallBack, CodeEnv);

        CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() 
            GGS_Disconnect(CodeEnv);
            __event_emitter__:RegisterEventCallBack(EventType.__GGS_DATA__, GGS_RecvDataCallBack, CodeEnv);
            __event_emitter__:RegisterEventCallBack(EventType.__GGS_CONNECT__, GGS_ConnectionCallBack, CodeEnv);
            __event_emitter__:RegisterEventCallBack(EventType.__GGS_DISCONNECT__, GGS_DisconnectionCallBack, CodeEnv);
        end);
    end
})
