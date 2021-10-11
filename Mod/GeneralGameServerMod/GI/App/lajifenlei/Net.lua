--[[
Title: Net
Author(s):  wxa
Date: 2021-06-01
Desc: Net
use the lib:
]]

local Net = inherit(ToolBase, module());

Net:Property("Connected", false, "IsConnected");

local EntityPlayerSyncMsg = "EntityPlayerSyncMsg";
local DestroyGarbageMsg = "DestroyGarbageMsg";
local CreateGarbageMsg = "CreateGarbageMsg";

local function SyncPlayerTrash(bAllData, username)
    -- print("------------------SyncPlayerTrash------------------------")
    TriggerNetworkEvent(EntityPlayerSyncMsg, __global__:GetMainPlayerTrash():GetSyncData(bAllData), username);
end

function Net:StartGame()
end

function Net:Connect(state)
    require("NetState");

    OnNetMainPlayerLogin(function()
        self:SetConnected(true);
        print("------------OnNetMainPlayerLogin----------")
        local mainPlayerTrash = __global__:GetMainPlayerTrash();
        mainPlayerTrash:SetUserName(GetUserName());
        mainPlayerTrash:OnWatcherDataChange(SyncPlayerTrash);
        SyncPlayerTrash(true);
    end);

    OnNetMainPlayerLogout(function()
        self:SetConnected(false);
        print("------------OnNetMainPlayerLogout----------")
    end);

    OnNetPlayerLogin(function(playerinfo)
        print("------------OnNetPlayerLogin----------")
        SyncPlayerTrash(true, playerinfo.username);
    end);

    OnNetPlayerLogout(function(playerinfo)
        local entity = GetEntityByUserName(playerinfo.username);
        if (entity) then entity:Destroy() end 
    end);

    RegisterNetworkEvent(EntityPlayerSyncMsg, function(data)
        -- print("------------RegisterNetworkEvent----------", EntityPlayerSyncMsg)
        local entity = GetEntityByUserName(data.__username__) or GetEntityByKey(data.__key__) or __global__:CreatePlayerTrash();
        entity:SetSyncData(data);
    end);

    RegisterNetworkEvent(DestroyGarbageMsg, function(data)
        print("===================RegisterNetworkEvent:DestroyGarbageMsg=============", data.__key__);
        DestroyEntityByKey(data.__key__);
    end);

    RegisterNetworkEvent(CreateGarbageMsg, function(data)
        __global__:LoadGarbageInfo(data);
    end);

    return NetInitState("lajifenlei", state);
end

function Net:DestroyGarbage(garbage)
    print("===================TriggerNetworkEvent:DestroyGarbageMsg=============", garbage:GetKey());
    TriggerNetworkEvent(DestroyGarbageMsg, {__key__ = garbage:GetKey()});
end

function Net:CreateGarbage(info)
    print("===================TriggerNetworkEvent:CreateGarbageMsg=============");
    TriggerNetworkEvent(CreateGarbageMsg, info);
end

Net:InitSingleton();