
--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level4");

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
        <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="43">
            <Field label="20" name="dist" value="20"/>
            <Block leftUnitCount="113" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="55">
                <Field label="180" name="angle" value="180"/>
                <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="67">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="113" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="79">
                        <Field label="90" name="angle" value="90"/>
                        <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="91">
                            <Field label="10" name="dist" value="10"/>
                            <Block leftUnitCount="113" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="103">
                                <Field label="180" name="angle" value="180"/>
                                <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="115">
                                    <Field label="20" name="dist" value="20"/>
                                </Block>
                            </Block>
                        </Block>
                    </Block>
                </Block>
            </Block>
        </Block>
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);

    -- self:SetWorkspaceXmlText(self:GetPassLevelXmlText());
    -- self:SetSpeed(5);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 摆放角色
    self:CreateSunBinEntity(10087,12,10065); 
    self:CreateTianShuCanJuanEntity(10087,12,10085);
    self:CreateTianShuCanJuanEntity(10097,12,10075);
    self:CreateGoalPointEntity(10077,12,10075);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(2, true);
    self:AddCodeLineTask(7, true);

    -- 设置视角
    SetCamera(30, 75, -90);
    SetCameraLookAtBlockPos(10087,11,10071);
end

Level:InitSingleton();
