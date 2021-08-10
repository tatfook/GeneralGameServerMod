
--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level1_1 = inherit(require("%gi%/App/sunzibingfa/Level/Level.lua"), module());

function Level1_1:ctor()
    self:SetLevelName("_level1.1");
end

function Level1_1:LoadLevel()
    CreateSunBinEntity(10093,13,10064);
    CreateTianShuCanJuanEntity(10083,13,10074);
    CreateTargetPositionEntity(10083,12,10084);
    SetCamera(30, 75, -90);
    SetCameraLookAtBlockPos(10093,13,10074);
end

function Level1_1:Edit()
    Level1_1._super.Edit(self);
    -- self:UnloadMap();
    -- cmd("/loadtemplate 10064 12 10064 level1.1");
    self:LoadLevel();
    cmd(format("/goto %s %s %s", 10090,13,10064));
end

Level1_1:InitSingleton();

-- -- 监听关卡加载事件,  完成关卡内容设置
-- On("LoadLevel", function()
-- end);

-- -- 监听关卡卸载事件,  移除关卡相关资源
-- On("UnloadLevel", function()
-- end)

-- -- 执行关卡代码前, 
-- On("RunLevelCodeBefore", function()
-- end)

-- -- 执行关卡代码后
-- On("RunLevelCodeAfter", function()
-- end)

-- -- 重置关卡
-- On("ResetLevel", function()
-- end);

-- -- 触发关卡重置
-- Emit("ResetLevel");