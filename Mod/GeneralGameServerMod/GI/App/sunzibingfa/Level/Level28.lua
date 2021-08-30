
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level28");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_BuildBridge"/>
        <block type="sunbin_BuildAir"/>
    </category>
    <category name="控制">
        <block type="while_true"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="121" type="while_true" isInputShadowBlock="false" isDraggable="true" topUnitCount="43">
            <Input label="" name="statement" value="">
                <Block leftUnitCount="125" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="54">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="125" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="66">
                        <Field label="90" name="angle" value="90"/>
                        <Block leftUnitCount="125" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="78">
                            <Field label="10" name="dist" value="10"/>
                            <Block leftUnitCount="125" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="90">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="125" type="sunbin_BuildBridge" isInputShadowBlock="false" isDraggable="true" topUnitCount="102">
                                    <Block leftUnitCount="125" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="114">
                                        <Field label="10" name="dist" value="10"/>
                                        <Block leftUnitCount="125" type="sunbin_BuildAir" isInputShadowBlock="false" isDraggable="true" topUnitCount="126">
                                            <Block leftUnitCount="125" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="138">
                                                <Field label="10" name="dist" value="10"/>
                                                <Block leftUnitCount="125" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="150">
                                                    <Field label="180" name="angle" value="180"/>
                                                    <Block leftUnitCount="125" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="162">
                                                        <Field label="10" name="dist" value="10"/>
                                                        <Block leftUnitCount="125" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="174">
                                                            <Field label="90" name="angle" value="90"/>
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
            </Input>
        </Block>
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 摆放角色
    self:CreateSunBinEntity(10083,12,10066); 
    self:CreateCrossFenceEntity(10073,12,10087);     
    self:CreateTianShuCanJuanEntity(10073,12,10096);
    self:CreateCrossFenceEntity(10094,12,10096);     
    self:CreateTianShuCanJuanEntity(10103,12,10096);
    self:CreateCrossFenceEntity(10103,12,10075);     
    self:CreateTianShuCanJuanEntity(10103,12,10066);
    self:CreateGoalPointEntity(10093,12,10066);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(3, true);
    self:AddCodeLineTask(12, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10084,12,10071);
end

Level:InitSingleton();
