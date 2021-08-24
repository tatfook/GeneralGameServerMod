
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level11");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_BuildBridge"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="-42" offsetX="-141">
        <Block leftUnitCount="162" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="36">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="162" type="sunbin_BuildBridge" isInputShadowBlock="false" isDraggable="true" topUnitCount="48">
                <Block leftUnitCount="162" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="60">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="162" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="72">
                        <Field label="180" name="angle" value="180"/>
                        <Block leftUnitCount="162" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="84">
                            <Field label="10" name="dist" value="10"/>
                            <Block leftUnitCount="162" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="96">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="162" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="108">
                                    <Field label="10" name="dist" value="10"/>
                                    <Block leftUnitCount="162" type="sunbin_BuildBridge" isInputShadowBlock="false" isDraggable="true" topUnitCount="120">
                                        <Block leftUnitCount="162" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="132">
                                            <Field label="10" name="dist" value="10"/>
                                            <Block leftUnitCount="162" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="144">
                                                <Field label="90" name="angle" value="90"/>
                                                <Block leftUnitCount="162" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="156">
                                                    <Field label="10" name="dist" value="10"/>
                                                </Block>
                                            </Block>
                                        </Block>
                                    </Block>
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
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 摆放角色
    self:CreateSunBinEntity(10084,12,10065); 
    self:CreateTianShuCanJuanEntity(10084,12,10085);
    self:CreateGoalPointEntity(10104,12,10085);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(11, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10087,12,10073);
end

Level:InitSingleton();
