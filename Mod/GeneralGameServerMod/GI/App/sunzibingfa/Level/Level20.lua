
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level20");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_Attack"/>
    </category>
    <category name="控制">
        <block type="while_true"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
<Blockly offsetY="0" offsetX="0">
<Block leftUnitCount="116" type="while_true" isInputShadowBlock="false" isDraggable="true" topUnitCount="34">
    <Input label="" name="statement" value="">
        <Block leftUnitCount="120" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="45">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="120" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="57">
                <Block leftUnitCount="120" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="69">
                    <Block leftUnitCount="120" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="81">
                        <Field label="180" name="angle" value="180"/>
                        <Block leftUnitCount="120" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="93">
                            <Field label="10" name="dist" value="10"/>
                            <Block leftUnitCount="120" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="105">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="120" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="117">
                                    <Field label="10" name="dist" value="10"/>
                                    <Block leftUnitCount="120" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="129">
                                        <Field label="90" name="angle" value="90"/>
                                        <Block leftUnitCount="120" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="141">
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
    local sunbin = self:CreateSunBinEntity(10072,12,10065); 
    sunbin:AddAttackType("wolf");
    
    self:CreateTianShuCanJuanEntity(10082,12,10065);
    self:CreateTianShuCanJuanEntity(10092,12,10075);
    self:CreateTianShuCanJuanEntity(10102,12,10085);
    local wolf1 = self:CreateWolfEntity(10072,12,10075);
    local wolf2 = self:CreateWolfEntity(10082,12,10085);
    local wolf3 = self:CreateWolfEntity(10092,12,10095);
    wolf1:SetVisibleRadius(0.1);
    wolf2:SetVisibleRadius(0.1);
    wolf3:SetVisibleRadius(0.1);
    wolf1:SetDefaultSkillRadius(0.1);
    wolf2:SetDefaultSkillRadius(0.1);
    wolf3:SetDefaultSkillRadius(0.1);
    wolf1:SetDefaultSkillPeerBlood(10);
    wolf2:SetDefaultSkillPeerBlood(10);
    wolf3:SetDefaultSkillPeerBlood(10);
    self:CreateGoalPointEntity(10102,12,10095);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddKillEnemyTask(3)
    self:AddTianShuCanJuanTask(3, true);
    self:AddCodeLineTask(10, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10084,12,10075);
end

Level:InitSingleton();
