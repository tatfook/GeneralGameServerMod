
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level21");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_BuildBridge"/>
    </category>
    <category name="控制">
        <block type="while_true"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="124" type="while_true" isInputShadowBlock="false" isDraggable="true" topUnitCount="63">
            <Input label="" name="statement" value="">
                <Block leftUnitCount="128" type="sunbin_BuildBridge" isInputShadowBlock="false" isDraggable="true" topUnitCount="74">
                    <Block leftUnitCount="128" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="86">
                        <Field label="10" name="dist" value="10"/>
                        <Block leftUnitCount="128" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="98">
                            <Field label="180" name="angle" value="180"/>
                            <Block leftUnitCount="128" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="110">
                                <Field label="10" name="dist" value="10"/>
                                <Block leftUnitCount="128" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="122">
                                    <Field label="90" name="angle" value="90"/>
                                    <Block leftUnitCount="128" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="134">
                                        <Field label="10" name="dist" value="10"/>
                                        <Block leftUnitCount="128" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="146">
                                            <Field label="180" name="angle" value="180"/>
                                            <Block leftUnitCount="128" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="158">
                                                <Field label="10" name="dist" value="10"/>
                                                <Block leftUnitCount="128" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="170">
                                                    <Field label="90" name="angle" value="90"/>
                                                    <Block leftUnitCount="128" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="182">
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
    self:CreateSunBinEntity(10082,12,10067); 
    self:CreateTianShuCanJuanEntity(10092,12,10067);
    self:CreateTianShuCanJuanEntity(10092,12,10077); 
    self:CreateGoalPointEntity(10092,12,10087); 

    self:CreateTorchEntity(10082,12,10077);
    self:CreateTorchEntity(10082,12,10087);
    self:CreateTorchEntity(10082,12,10097);

    self:CreateWolfEntity(10088,12,10067):SetVisibleRadius(4);
    self:CreateWolfEntity(10088,12,10077):SetVisibleRadius(4);  
    self:CreateWolfEntity(10088,12,10087):SetVisibleRadius(4);  
    local trap_pos_list = {{10090,12,10067}, {10090,12,10077}, {10090,12,10087}};
    for _, pos in ipairs(trap_pos_list) do
        self:CreateTrapEntity(pos[1], pos[2], pos[3]);
        self:CreateTrapEntity(pos[1] - 1, pos[2], pos[3] - 1);
        self:CreateTrapEntity(pos[1] - 1, pos[2], pos[3] + 1);
        self:CreateTrapEntity(pos[1] + 1, pos[2], pos[3] - 1);
        self:CreateTrapEntity(pos[1] + 1, pos[2], pos[3] + 1);
    end

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(2, true);
    self:AddCodeLineTask(11, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10087,11,10073);
end

Level:InitSingleton();
