
--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导API 
-----------------------------------------------
local Date = NPL.load("Mod/GeneralGameServerMod/Tutorial/Demo/Date.lua");
-----------------------------------------------
]]

local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua", IsDevEnv);

local Date = TutorialSandbox.Date;

local DateDemo = NPL.export();

-- 获取服务器时间
function DateDemo.Demo()
    local date = Date:new(); -- 当前时间

    print(date:GetTimeStamp());

    print(date:GetDate("%Y-%m-%d"));
end

