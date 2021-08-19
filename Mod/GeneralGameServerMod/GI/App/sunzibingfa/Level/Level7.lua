
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level7");

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
        <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="37">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="49">
                <Field label="90" name="angle" value="90"/>
                <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="61">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="112" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="73">
                        <Field label="90" name="angle" value="90"/>
                        <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="85">
                            <Field label="20" name="dist" value="20"/>
                            <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="97">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="109">
                                    <Field label="20" name="dist" value="20"/>
                                    <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="121">
                                        <Field label="90" name="angle" value="90"/>
                                        <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="133">
                                            <Field label="30" name="dist" value="30"/>
                                            <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="145">
                                                <Field label="90" name="angle" value="90"/>
                                                <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="157">
                                                    <Field label="10" name="dist" value="10"/>
                                                    <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="169">
                                                        <Field label="180" name="angle" value="180"/>
                                                        <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="181">
                                                            <Field label="10" name="dist" value="10"/>
                                                            <Block leftUnitCount="112" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="193">
                                                                <Field label="90" name="angle" value="90"/>
                                                                <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="205">
                                                                    <Field label="30" name="dist" value="30"/>
                                                                    <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="217">
                                                                        <Field label="90" name="angle" value="90"/>
                                                                        <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="229">
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
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- -- 摆放角色
    self:CreateSunBinEntity(10076,12,10064); 
    self:CreateTianShuCanJuanEntity(10096,12,10064);
    self:CreateGoalPointEntity(10116,12,10094);
    local trap_pos_list = {{10076,12,10084}, {10076,12,10094}, {10086,12,10064}, {10096,12,10074}, {10096,12,10084}, {10116,12,10084}, {10116,12,10074}, {10116,12,10064}};
    for _, pos in ipairs(trap_pos_list) do
        self:CreateTrapEntity(pos[1], pos[2], pos[3]);
        self:CreateTrapEntity(pos[1] - 1, pos[2], pos[3] - 1);
        self:CreateTrapEntity(pos[1] - 1, pos[2], pos[3] + 1);
        self:CreateTrapEntity(pos[1] + 1, pos[2], pos[3] - 1);
        self:CreateTrapEntity(pos[1] + 1, pos[2], pos[3] + 1);
    end

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(17, true);

    -- -- 设置视角
    SetCamera(50, 75, -90);
    SetCameraLookAtBlockPos(10096,12,10079);
end

Level:InitSingleton();
