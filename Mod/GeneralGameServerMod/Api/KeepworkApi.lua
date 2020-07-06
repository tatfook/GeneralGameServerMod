--[[
Title: KeepworkApi
Author(s): wxa
Date: 2020/7/2
Desc: keepwork api
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Api/KeepworkApi.lua");
local KeepworkApi = commonlib.gettable("Mod.GeneralGameServerMod.Api.KeepworkApi");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/GetUrl.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
local Encoding = commonlib.gettable("System.Encoding");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local KeepworkApi = commonlib.gettable("Mod.GeneralGameServerMod.Api.KeepworkApi");

function DefineApi(fullname, url, method, tokenRequired, configs, prepFunc, postFunc)
    if (not prepFunc) then 
        -- PreProcessor
        prepFunc = function(self, inputParams, callbackFunc, option)
            return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, fullname);
        end
    end

    if (not postFunc) then
        -- Post Processor
        postFunc = function(self, err, msg, data)
            return HttpWrapper.default_postFunc(self, err, msg, data, fullname); 
       end
    end

    HttpWrapper.Create(fullname, url, method, tokenRequired, configs, prepFunc, postFunc);
end

-- DefineApi("Mod.GeneralGameServerMod.Api.KeepworkApi.getUserDetail_", "%MAIN%/gosys/v0/exchangeRules", "GET", false, nil);
function GetUrl(params, callback, options)
    
end

function KeepworkApi:GetBaseUrl()
    return "https://api.keepwork.com";
end

function KeepworkApi:GetToken()
    return System.User.keepworktoken;
end

function KeepworkApi:HttpRequest(params, callback, options)
    local baseUrl = self:GetBaseUrl();
    local index = string.find(params.url, "^http[s]?://");
    if (not index) then params.url = baseUrl .. params.url; end
    if (params.json == nil) then params.json = true; end
    params.headers = params.headers or {};
    params.headers["Authorization"] = string.format("Bearer %s", self:GetToken());
    return System.os.GetUrl(params, callback, options);
end

-- https://api.keepwork.com/core/v0/users/:id/detail
function KeepworkApi:GetUserDetail(username, callback)
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
    local url = self:GetBaseUrl() .. "/core/v0/users/" .. id .. "/detail";
    return self:HttpRequest({
        url = url,
        method = "GET",
    }, callback);
end

-- https://api.keepwork.com/core/v0/projects?userId=3
function KeepworkApi:GetUserProjects(userId, callback) 
    local url = self:GetBaseUrl() .. "/core/v0/projects";
    return self:HttpRequest({
        url = url,
        method = "GET",
        qs = {
            userId = userId,
            type = 1,               -- 取世界项目
            ["x-per-page"] = 1000,  -- 先取全部后续优化
            ["x-order"] = "updatedAt-desc", -- 按更新时间降序
        },
    },  callback);
end

-- https://api.keepwork.com/core/v0/favorites/exist?objectId=3&objectType=0
function KeepworkApi:IsFollow(userId)
    local url = self:GetBaseUrl() .. "/core/v0/favorites/exist";
    return self:HttpRequest({
        url = url,
        method = "GET",
        qs = {
            objectId = userId,
            objectType = 0,
        },
    },  callback);
end
