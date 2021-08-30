
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level24");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_BuildBridge"/>
    </category>
    <category name="控制">
        <block type="while_true"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    ]]);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 摆放角色
    -- self:CreateSunBinEntity(10083,12,10066); 
    -- self:CreateTianShuCanJuanEntity(10103,12,10086);
    -- self:CreateGoalPointEntity(10093,12,10086);

    -- 添加任务
    -- self:AddGoalPointTask(1);
    -- self:AddTianShuCanJuanTask(1, true);
    -- self:AddCodeLineTask(1, true);

    -- 设置视角
    -- SetCamera(40, 75, -90);
    -- SetCameraLookAtBlockPos(10088,12,10076);
end

Level:InitSingleton();
