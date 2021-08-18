
--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level1");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="159" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="83">
            <Field label="20" name="dist" value="20"/>
        </Block>
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 创建角色
    self:CreateSunBinEntity(10090,12,10067); 
    self:CreateTianShuCanJuanEntity(10090,12,10077);
    self:CreateGoalPointEntity(10090,12,10087);
    self:CreatePangJuanEntity(10090,12,10089);
    
    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(1, true);

    -- 调整场景
    SetCamera(30, 75, -90);
    SetCameraLookAtBlockPos(10090,12,10077);
end

-- 代码执行前 默认完成场景重置操作
function Level:RunLevelCodeBefore()
    Level._super.RunLevelCodeBefore(self);
end

--  代码执行完成 默认完成检测主玩家是否到达指定地点
function Level:RunLevelCodeAfter()
    Level._super.RunLevelCodeAfter(self);
    -- 可在此自定义通关逻辑  默认到达目标点
end

Level:InitSingleton();
