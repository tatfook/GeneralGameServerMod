--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level = inherit(require("Level"), gettable("Level")) ;

-- 监听关卡加载事件,  完成关卡内容设置
function Level:LoadLevel()
end

-- 监听关卡卸载事件,  移除关卡相关资源
function Level:UnloadLevel()
end

-- 执行关卡代码前, 
function Level:RunLevelCodeBefore()
end

-- 执行关卡代码后
function Level:RunLevelCodeAfter()
end

-- 重置关卡
function Level:ResetLevel()
end

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