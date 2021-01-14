
--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导API 
-----------------------------------------------
local Http = NPL.load("Mod/GeneralGameServerMod/Tutorial/Demo/Http.lua");
-----------------------------------------------
]]

local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua", IsDevEnv);

local KeepworkAPI = TutorialSandbox:GetKeepworkAPI();

local HttpDemo = NPL.export();

-- 获取服务器时间
function HttpDemo.GetServerTime()
    KeepworkAPI:Get("keepworks/currentTime"):Then(function(response)
        -- 请求成功
        echo({
            response.status,  -- 响应码
            response.header,  -- 响应头
            response.data,    -- 响应数据
        });
    end):Catch(function(response)
        -- 请求失败
    end);
end

