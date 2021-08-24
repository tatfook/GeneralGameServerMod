
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level10");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="126" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="36">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="126" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="48">
                <Field label="90" name="angle" value="90"/>
                <Block leftUnitCount="126" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="60">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="126" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="72">
                        <Field label="90" name="angle" value="90"/>
                        <Block leftUnitCount="126" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="84">
                            <Field label="10" name="dist" value="10"/>
                        </Block>
                    </Block>
                </Block>
            </Block>
        </Block>
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 摆放角色
    self:CreateSunBinEntity(10082,12,10066); 
    self:CreateTianShuCanJuanEntity(10082,12,10076);
    self:CreateGoalPointEntity(10092,12,10086);
    self:CreateWolfEntity(10082,12,10081):Turn(90);
    self:CreateWolfEntity(10092,12,10066):Turn(180);
    self:CreateHunterEntity(10084,12,10074):TurnLeft(90);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(5, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10082,12,10070);
end

Level:InitSingleton();
