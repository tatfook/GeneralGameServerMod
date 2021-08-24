
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level9");

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
        <Block leftUnitCount="146" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="63">
            <Field label="90" name="angle" value="90"/>
            <Block leftUnitCount="146" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="75">
                <Field label="10" name="dist" value="10"/>
                <Block leftUnitCount="146" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="87">
                    <Field label="180" name="angle" value="180"/>
                    <Block leftUnitCount="146" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="99">
                        <Field label="10" name="dist" value="10"/>
                        <Block leftUnitCount="146" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="111">
                            <Field label="90" name="angle" value="90"/>
                            <Block leftUnitCount="146" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="123">
                                <Field label="30" name="dist" value="30"/>
                                <Block leftUnitCount="146" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="135">
                                    <Field label="90" name="angle" value="90"/>
                                    <Block leftUnitCount="146" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="147">
                                        <Field label="10" name="dist" value="10"/>
                                        <Block leftUnitCount="146" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="159">
                                            <Field label="90" name="angle" value="90"/>
                                            <Block leftUnitCount="146" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="171">
                                                <Field label="20" name="dist" value="20"/>
                                                <Block leftUnitCount="146" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="183">
                                                    <Field label="180" name="angle" value="180"/>
                                                    <Block leftUnitCount="146" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="195">
                                                        <Field label="10" name="dist" value="10"/>
                                                        <Block leftUnitCount="146" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="207">
                                                            <Field label="90" name="angle" value="90"/>
                                                            <Block leftUnitCount="146" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="219">
                                                                <Field label="10" name="dist" value="10"/>
                                                                <Block leftUnitCount="146" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="231">
                                                                    <Field label="90" name="angle" value="90"/>
                                                                    <Block leftUnitCount="146" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="243">
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
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 摆放角色
    self:CreateSunBinEntity(10079,12,10065); 
    self:CreateTianShuCanJuanEntity(10089,12,10075);
    self:CreateGoalPointEntity(10099,12,10095);
    self:CreateWolfEntity(10089,12,10085):Turn(180);
    self:CreateTorchEntity(10089,12,10065);

    -- 陷阱
    local trap_pos_list = {{10089,12,10080}};
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
    self:AddCodeLineTask(16, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10085,12,10075);
end

Level:InitSingleton();
