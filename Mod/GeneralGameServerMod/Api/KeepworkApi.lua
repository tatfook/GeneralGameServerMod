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

function KeepworkApi:GetBaseUrl()
    return "https://api.keepwork.com";
end

-- https://api.keepwork.com/core/v0/users/:id/detail
function KeepworkApi:GetUserDetail(username, callback)
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
    local url = self:GetBaseUrl() .. "/core/v0/users/" .. id .. "/detail";
    return System.os.GetUrl({
        url = url,
        method = "GET",
    }, callback);
end

-- https://api.keepwork.com/core/v0/projects?userId=3
function KeepworkApi:GetUserProjects(userId, callback) 
    local url = self:GetBaseUrl() .. "/core/v0/projects";
    return System.os.GetUrl({
        url = url,
        method = "GET",
        qs = {
            userId = userId,
        },
    },  callback);
end