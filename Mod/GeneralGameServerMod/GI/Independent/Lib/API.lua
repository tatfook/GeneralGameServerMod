--[[
Title: API
Author(s):  wxa
Date: 2021-06-01
Desc: 模块API的简化
use the lib:
------------------------------------------------------------
local API = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/API.lua");
------------------------------------------------------------
]]

local API = module("API");

-- 定义快捷方式接口
function GetNetModule()
    return require("Net");
end

function NetLock(...)
    return GetNetModule():Lock(...);
end

function NetUnlock(...)
    return GetNetModule():Unlock(...);
end

function NetSetSharedData(key, val)
    GetNetModule():SetShareData({[key] = val})
end

function NetGetSharedData(key, default_val)
    return GetNetModule():GetShareData()[key] or default_val;
end

function NetInitSharedData(init_shared_data)
    local __net_shared_data_inited__ = NetGetSharedData("__net_shared_data_inited__");
    local is_lock = false;

    local function init_shared_data_func()
        GetNetModule():SetShareData(init_shared_data);
        NetSetSharedData("__net_shared_data_inited__", true);
        is_lock = true;
    end

    if (not __net_shared_data_inited__) then
        if (NetLock()) then
            -- 上锁成功 进行初始化操作
            init_shared_data_func();
        else 
            -- 上锁失败 等待玩家初始化
            local wait_time, wait_total_time = 300, 0;
            while(not __net_shared_data_inited__) do
                sleep(wait_time);
                __net_shared_data_inited__ = NetGetSharedData("__net_shared_data_inited__");
                wait_total_time = wait_total_time + wait_time;
                -- 
                if (wait_total_time > 5000) then
                    wait_total_time = 0;
                    if (NetLock()) then 
                        init_shared_data_func();
                    end
                end
            end
        end
    end
    
    if (is_lock) then NetUnlock() end 
end

function SetSharedData(key, val)
    GetNetModule():SetShareData({[key] = val})
end

function GetSharedData(key, default_val)
    return GetNetModule():GetShareData()[key] or default_val;
end

function OnSharedDataChanged(key, callback)
    return GetNetModule():OnShareDataItem(key, callback);
end

function GetNetStateModule()
    return require("NetState");
end

function GetUserData(key, default_val)
    return GetNetStateModule():GetUserState()[key] or default_val;
end

function SetUserData(key, val)
    GetNetStateModule():GetUserState()[key] = val;
end

function GetAllUserData()
    return GetNetStateModule():GetAllUserState();
end

function RegisterNetworkEvent(msgname, callback)
    GetNetModule():On(msgname, callback);
end

function TriggerNetworkEvent(msgname, msgdata, username)
    GetNetModule():Emit(msgname, msgdata);
end

function RegisterNetConnectEvent(callback)
    GetNetModule():Connect(callback);
end

function GetNetPlayerModule()
    return require("NetPlayer");
end

function OnNetMainPlayerLogin(callback)
    GetNetPlayerModule():OnMainPlayerLogin(callback);
end

function OnNetMainPlayerLogout(callback)
    GetNetPlayerModule():OnMainPlayerLogout(callback);
end

function OnNetPlayerLogin(callback)
    GetNetPlayerModule():OnPlayerLogin(callback);
end

function OnNetPlayerLogout(callback)
    GetNetPlayerModule():OnPlayerLogout(callback);
end

function GetNetRankModule()
    return require("NetRank");
end

function GetNetEntityModule()
    return require("NetEntity");
end

-- 获取KeepWorkAPI
local __keepwork_api__ = nil;
function GetKeepworkAPI()
    if (__keepwork_api__) then return __keepwork_api__ end 

    __keepwork_api__ = require("Http"):new():Init({
        baseURL = "https://api.keepwork.com/core/v0/",
        headers = {
            ["content-type"] = "application/json", 
        },
        transformRequest = function(request)
            request.headers["Authorization"] = string.format("Bearer %s", GetSystemUser().keepworktoken);
        end
    });

    return __keepwork_api__;
end

local __Net_api__ = nil;
function GetNetAPI()
    if (__Net_api__) then return __Net_api__ end 
    __Net_api__ = require("Http"):new():Init({
        baseURL = IsDevEnv and "http://127.0.0.1:9000/api/v0/" or "http://ggs.keepwork.com:9000/api/v0/",
        headers = {["content-type"] = "application/json"},
    });

    return __Net_api__;
end

function GetEntityModule()
    return require("Entity");
end

function GetEntityByKey(key)
    return GetEntityModule():GetEntityByKey(key);
end

function GetAllEntity()
    return GetEntityModule():GetAllEntity();
end

function CreateEntity(opts)
    return GetEntityModule():new():Init(opts);
end

function DestroyEntityByKey(key)
    local entity = GetEntityModule():GetEntityByKey(key);
    if (not entity) then return end
    entity:Destroy();
end

function GetEntityByUserName(name)
    return GetEntityModule():GetEntityByUserName(name);
end

function DestroyEntityByName(name)
    local entity = GetEntityByUserName(name);
    if (not entity) then return end
    entity:Destroy();
end

function RunForEntity(entity, func)
    local entity = type(entity) == "table" and entity or GetEntityModule():GetEntityByUserName(name);
    if (not entity) then return end
    return entity:Run(func);
end

function ShowEntityEditor(key)
    local entity = GetEntityModule():GetEntityByKey(key);
    if (not entity) then return end 
    local screen_width = GetScreenSize();
    local width = math.floor(screen_width / 2);
    SetSceneMarginRight(width);
    ShowWindow({
        __entity__ = entity,
        OnClose = function()
            SetSceneMarginRight(0);
        end,
    }, {
        parent = GetRootUIObject(),
        url = "%gi%/Independent/UI/EntityEditor.html",
        width = width,
        height = "100%",
        alignment = "_rt",
    });
end

function GetGoodsModule()
    return require("Goods");
end

function CreateGoods(opts)
    return GetGoodsModule():new():Init(opts);
end

function GetGoodsByName(name)
    if (type(name) == "table") then return name end 
    return GetGoodsModule():GetGoodsByName(name);
end

function GetSkillModule()
    return require("Skill");
end

function CreateSkill(opts)
    return GetSkillModule():new():Init(opts);
end

function GetEntityPlayerModule()
    return require("EntityPlayer");
end

function CreateEntityPlayer(opts)
    return GetEntityPlayerModule():new():Init(opts);
end
