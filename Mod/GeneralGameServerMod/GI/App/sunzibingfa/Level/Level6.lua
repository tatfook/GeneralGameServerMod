
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level6");

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
        <Block leftUnitCount="119" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="34">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="119" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="46">
                <Field label="90" name="angle" value="90"/>
                <Block leftUnitCount="119" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="58">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="119" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="70">
                        <Field label="90" name="angle" value="90"/>
                        <Block leftUnitCount="119" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="82">
                            <Field label="20" name="dist" value="20"/>
                            <Block leftUnitCount="119" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="94">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="119" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="106">
                                    <Field label="10" name="dist" value="10"/>
                                    <Block leftUnitCount="119" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="118">
                                        <Field label="90" name="angle" value="90"/>
                                        <Block leftUnitCount="119" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="130">
                                            <Field label="10" name="dist" value="10"/>
                                            <Block leftUnitCount="119" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="142">
                                                <Field label="180" name="angle" value="180"/>
                                                <Block leftUnitCount="119" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="154">
                                                    <Field label="20" name="dist" value="20"/>
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

    -- -- 摆放角色
    self:CreateSunBinEntity(10077,12,10071):Turn(90); 
    self:CreateTianShuCanJuanEntity(10097,12,10071);
    self:CreateGoalPointEntity(10117,12,10071);
    self:CreateWolfEntity(10092,12,10066):Turn(-90);

    -- -- -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(11, true);

    -- -- 设置视角
    SetCamera(30, 75, -90);
    SetCameraLookAtBlockPos(10087,12,10071);
end

Level:InitSingleton();
