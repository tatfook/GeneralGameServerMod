
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level19");

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
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="129" type="while_true" isInputShadowBlock="false" isDraggable="true" topUnitCount="57">
            <Input label="" name="statement" value="">
                <Block leftUnitCount="133" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="68">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="133" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="80">
                        <Field label="180" name="angle" value="180"/>
                        <Block leftUnitCount="133" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="92">
                            <Field label="10" name="dist" value="10"/>
                            <Block leftUnitCount="133" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="104">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="133" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="116">
                                    <Field label="20" name="dist" value="20"/>
                                    <Block leftUnitCount="133" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="128">
                                        <Field label="180" name="angle" value="180"/>
                                        <Block leftUnitCount="133" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="140">
                                            <Field label="10" name="dist" value="10"/>
                                            <Block leftUnitCount="133" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="152">
                                                <Field label="90" name="angle" value="90"/>
                                                <Block leftUnitCount="133" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="164">
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
    self:CreateSunBinEntity(10069,12,10065); 
    self:CreateTianShuCanJuanEntity(10089,12,10065); 
    self:CreateTianShuCanJuanEntity(10099,12,10075);
    self:CreateTianShuCanJuanEntity(10109,12,10085);
    self:CreateGoalPointEntity(10099,12,10095);
    
    self:CreateWolfEntity(10079,12,10065);
    self:CreateWolfEntity(10079,12,10075);  
    self:CreateWolfEntity(10089,12,10075);  
    self:CreateWolfEntity(10089,12,10085);  
    self:CreateWolfEntity(10099,12,10085);  
    local trap_pos_list = {{10084,12,10065}, {10079,12,10080}, {10094,12,10075}, {10089,12,10090}, {10104,12,10085}};
    for _, pos in ipairs(trap_pos_list) do
        self:CreateTrapEntity(pos[1], pos[2], pos[3]);
        self:CreateTrapEntity(pos[1] - 1, pos[2], pos[3] - 1);
        self:CreateTrapEntity(pos[1] - 1, pos[2], pos[3] + 1);
        self:CreateTrapEntity(pos[1] + 1, pos[2], pos[3] - 1);
        self:CreateTrapEntity(pos[1] + 1, pos[2], pos[3] + 1);
    end
    self:CreateTorchEntity(10089,12,10095);
    self:CreateTorchEntity(10079,12,10085);
    self:CreateTorchEntity(10069,12,10075);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(3, true);
    self:AddCodeLineTask(10, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10079,12,10069);
end

Level:InitSingleton();
