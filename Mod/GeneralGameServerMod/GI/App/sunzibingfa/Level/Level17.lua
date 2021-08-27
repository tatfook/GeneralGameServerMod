
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level17");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
    </category>
    <category name="控制">
        <block type="while_true"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
<Blockly offsetY="-66" offsetX="-33">
<Block leftUnitCount="135" type="while_true" isInputShadowBlock="false" isDraggable="true" topUnitCount="58">
    <Input label="" name="statement" value="">
        <Block leftUnitCount="139" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="69">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="139" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="81">
                <Field label="90" name="angle" value="90"/>
                <Block leftUnitCount="139" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="93">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="139" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="105">
                        <Field label="180" name="angle" value="180"/>
                        <Block leftUnitCount="139" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="117">
                            <Field label="20" name="dist" value="20"/>
                            <Block leftUnitCount="139" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="129">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="139" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="141">
                                    <Field label="10" name="dist" value="10"/>
                                    <Block leftUnitCount="139" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="153">
                                        <Field label="90" name="angle" value="90"/>
                                        <Block leftUnitCount="139" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="165">
                                            <Field label="10" name="dist" value="10"/>
                                            <Block leftUnitCount="139" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="177">
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
    self:CreateSunBinEntity(10069,12,10076):TurnRight(90); 
    self:CreateTianShuCanJuanEntity(10079,12,10066);
    self:CreateGoalPointEntity(10109,12,10076);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(11, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10079,12,10076);
end

Level:InitSingleton();
