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

local function SyncPlayerTrash(bAllData, username)
    -- print("------------------SyncPlayerTrash------------------------")
    TriggerNetworkEvent(EntityPlayerSyncMsg, __main_player_trash__:GetSyncData(bAllData), username);
end

function Net:StartGame()
end

function Net:Connect(state)
    require("NetState");

    OnNetMainPlayerLogin(function()
        self:SetConnected(true);
        print("------------OnNetMainPlayerLogin----------")
        __main_player_trash__:SetUserName(GetUserName());
        __main_player_trash__:OnWatcherDataChange(SyncPlayerTrash);
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

    return NetInitState("lajifenlei", state);
end

Net:InitSingleton();