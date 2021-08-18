
--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level3");

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
<Block leftUnitCount="159" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="129">
    <Field label="20" name="dist" value="20"/>
    <Block leftUnitCount="159" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="141">
        <Field label="90" name="angle" value="90"/>
        <Block leftUnitCount="159" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="153">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="159" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="165">
                <Field label="90" name="angle" value="90"/>
                <Block leftUnitCount="159" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="177">
                    <Field label="20" name="dist" value="20"/>
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

    self:CreateSunBinEntity(10083,12,10065); 
    self:CreateTianShuCanJuanEntity(10093,12,10085);
    self:CreateGoalPointEntity(10093,12,10065);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(5, true);

    SetCamera(30, 75, -90);
    SetCameraLookAtBlockPos(10088,11,10074);
end

Level:InitSingleton();
