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

local function ConnectionCallBack(__code_env__, ...)
    __event_emitter__:TriggerEventCallBack(EventType.__GGS_CONNECT__, ...);
end

local function DisconnectionCallBack(__code_env__, ...)
    __event_emitter__:TriggerEventCallBack(EventType.__GGS_DISCONNECT__, ...);
end

GIGeneralGameClient:GetClientDataHandlerClass():SetRecvDataCallBack(RecvDataCallBack);
GIGeneralGameClient:SetConnectionCallBack(ConnectionCallBack);
GIGeneralGameClient:SetDisconnectionCallBack(DisconnectionCallBack);

local function __G_Connect__(opts)
    -- 所有独立沙盒公用GGS连接
    if (GIGeneralGameClient:IsLogin()) then return ConnectionCallBack() end
    -- 未连接进行连接
    GIGeneralGameClient:LoadWorld(opts);
end
setfenv(__G_Connect__, __G__);

local function __G_Send__(data, to, action, username)
    local dataHandler = GIGeneralGameClient:GetClientDataHandler();
    if (not dataHandler) then return end
    DATA.__to__, DATA.__action__, DATA.__data__, DATA.__username__ = to, action, data, username;
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




local function GGS_Connect(__code_env__, callback)
    local username = __code_env__.GetUserName();
    __code_env__.RegisterEventCallBack(EventType.__GGS_CONNECT__, callback);
    __G_Connect__({username = username});
end

local function GGS_Send(__code_env__,  data, to, action)
    __G_Send__(data, to, action, __code_env__.GetUserName());
end

local function GGS_Recv(__code_env__, callback)
    __code_env__.RegisterEventCallBack(EventType.__GGS_DATA__, callback);
end

local function GGS_Disconnect(__code_env__, callback)
    if (type(callback) == "function") then
        __code_env__.RegisterEventCallBack(EventType.__GGS_DISCONNECT__, callback);
    else 
        __G_Disconnect__();
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

        CodeEnv.GGS_Connect = function(...) return GGS_Connect(CodeEnv, ...) end
        CodeEnv.GGS_Send = function(...) return GGS_Send(CodeEnv, ...) end
        CodeEnv.GGS_Recv = function(...) return GGS_Recv(CodeEnv, ...) end
        CodeEnv.GGS_Disconnect = function(...) return GGS_Disconnect(CodeEnv, ...) end
        
        __event_emitter__:RegisterEventCallBack(EventType.__GGS_DATA__, GGS_RecvDataCallBack, CodeEnv);
        __event_emitter__:RegisterEventCallBack(EventType.__GGS_CONNECT__, GGS_ConnectionCallBack, CodeEnv);
        __event_emitter__:RegisterEventCallBack(EventType.__GGS_DISCONNECT__, GGS_DisconnectionCallBack, CodeEnv);

        CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() 
            __G_Disconnect__(); 
            __event_emitter__:RegisterEventCallBack(EventType.__GGS_DATA__, GGS_RecvDataCallBack, CodeEnv);
            __event_emitter__:RegisterEventCallBack(EventType.__GGS_CONNECT__, GGS_ConnectionCallBack, CodeEnv);
            __event_emitter__:RegisterEventCallBack(EventType.__GGS_DISCONNECT__, GGS_DisconnectionCallBack, CodeEnv);
        end);
    end
})
