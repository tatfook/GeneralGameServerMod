--[[
Title: SandBox
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local SandBox = NPL.load("Mod/GeneralGameServerMod/GI/Independent/SandBox.lua");
------------------------------------------------------------
]]

local Independent = NPL.load("./Independent.lua", IsDevEnv);

local SandBox = commonlib.inherit(Independent, NPL.export());

function SandBox:ctor()
    self:SetErrorExit(false);
    self:SetShareMouseKeyBoard(true);
end

function SandBox:GetAPI()
	-- print("===========================SandBox:GetAPI==================================");
    self:Start();
    return self:GetCodeEnv();
end

-- 获取代码方块专属API
function SandBox:GetCodeBlockAPI()
    if (self.CodeBlockAPI) then return self.CodeBlockAPI end

    local API = self:GetAPI();
    self.CodeBlockAPI = {
        API = API,
        
        call = API.__call__,
        
        -- 注册网络消息
        registerNetworkEvent = function(name, callback)
            if (name == "ggs_user_joined") then
                -- 玩家加入 包含自己
                API.GetGGSPlayerModule():OnPlayerLogin(callback);
            elseif (name == "ggs_user_left") then
                -- 玩家退出 包含自己
                API.GetGGSPlayerModule():OnPlayerLogout(callback); 
            elseif (name == "ggs_started") then
                -- 连接成功 
                API.GetGGSModule():Connect(callback);
            elseif (name == "ggs_shutdown") then 
                -- 服务器不关闭
            else
                API.RegisterNetworkEvent(name, callback);
            end
        end,

        -- 广播网络消息
        broadcastNetworkEvent = function(name, msg)
            API.TriggerNetworkEvent(name, msg);
        end,

        -- 显示排行榜
        showRanking = function()
            API.__call__(function()
                API.GetGGSRankModule():ShowUI();
            end);
        end,

        -- 设置排行榜字段值
        setRankField = function(key, val)
            API.GetGGSRankModule():SetFieldValue(key, val);
        end,

        -- 获取共享数据
        getSharedData = function(key, default_val)
            return API.GetSharedData(key, default_val);
        end,

        -- 设置共享数据
        setSharedData = function(key, val)
            return API.SetSharedData(key, val);
        end,

        -- 监控共享数据
        onSharedDataChanged = function(key, callback)
            return API.OnSharedDataChanged(key, callback);
        end,
        
        -- 获取用户数据 
        getUserData = function(key, default_val, username)
            return API.GetGGSStateModule():GetUserState(username):Get(key, default_val);
        end,

        -- 设置用户数据
        setUserData = function(key, value)
            return API.GetGGSStateModule():GetUserState(username):Set(key, value);
        end
    }

    return self.CodeBlockAPI;
end

SandBox:InitSingleton();
