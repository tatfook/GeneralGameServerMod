
--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level5");

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
        <Block leftUnitCount="129" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="49">
            <Field label="90" name="angle" value="90"/>
            <Block leftUnitCount="129" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="61">
                <Field label="10" name="dist" value="10"/>
                <Block leftUnitCount="129" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="73">
                    <Field label="180" name="angle" value="180"/>
                    <Block leftUnitCount="129" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="85">
                        <Field label="10" name="dist" value="10"/>
                        <Block leftUnitCount="129" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="97">
                            <Field label="90" name="angle" value="90"/>
                            <Block leftUnitCount="129" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="109">
                                <Field label="20" name="dist" value="20"/>
                                <Block leftUnitCount="129" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="121">
                                    <Field label="180" name="angle" value="180"/>
                                    <Block leftUnitCount="129" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="133">
                                        <Field label="10" name="dist" value="10"/>
                                        <Block leftUnitCount="129" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="145">
                                            <Field label="90" name="angle" value="90"/>
                                            <Block leftUnitCount="129" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="157">
                                                <Field label="20" name="dist" value="20"/>
                                                <Block leftUnitCount="129" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="169">
                                                    <Field label="90" name="angle" value="90"/>
                                                    <Block leftUnitCount="129" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="181">
                                                        <Field label="10" name="dist" value="10"/>
                                                        <Block leftUnitCount="129" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="193">
                                                            <Field label="180" name="angle" value="180"/>
                                                            <Block leftUnitCount="129" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="205">
                                                                <Field label="10" name="dist" value="10"/>
                                                                <Block leftUnitCount="129" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="217">
                                                                    <Field label="90" name="angle" value="90"/>
                                                                    <Block leftUnitCount="129" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="229">
                                                                        <Field label="10" name="dist" value="10"/>
                                                                        <Block leftUnitCount="129" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="241">
                                                                            <Field label="90" name="angle" value="90"/>
                                                                            <Block leftUnitCount="129" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="253">
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
    self:CreateSunBinEntity(10083,12,10066); 
    self:CreateTianShuCanJuanEntity(10083,12,10086);
    self:CreateTianShuCanJuanEntity(10103,12,10086);
    self:CreateGoalPointEntity(10093,12,10086);
    self:CreateWolfEntity(10093,12,10076):Turn(180);
    self:CreateTorchEntity(10073,12,10066);

    -- -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(2, true);
    -- self:AddCodeLineTask(7, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10088,12,10076);
end

Level:InitSingleton();
