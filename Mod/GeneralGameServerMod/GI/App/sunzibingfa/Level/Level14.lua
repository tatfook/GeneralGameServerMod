
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level14");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_Attack"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="107" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="36">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="107" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="48">
                <Field label="90" name="angle" value="90"/>
                <Block leftUnitCount="107" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="60">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="107" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="72">
                        <Block leftUnitCount="107" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="84">
                            <Block leftUnitCount="107" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="96">
                                <Field label="180" name="angle" value="180"/>
                                <Block leftUnitCount="107" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="108">
                                    <Field label="10" name="dist" value="10"/>
                                    <Block leftUnitCount="107" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="120">
                                        <Field label="90" name="angle" value="90"/>
                                        <Block leftUnitCount="107" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="132">
                                            <Field label="20" name="dist" value="20"/>
                                            <Block leftUnitCount="107" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="144">
                                                <Block leftUnitCount="107" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="156">
                                                    <Block leftUnitCount="107" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="168">
                                                        <Field label="90" name="angle" value="90"/>
                                                        <Block leftUnitCount="107" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="180">
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
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 摆放角色
    local sunbin = self:CreateSunBinEntity(10074,12,10072); 
    sunbin:AddAttackType("wolf");
    sunbin:TurnRight(90);

    self:CreateTianShuCanJuanEntity(10094,12,10072);
    self:CreateGoalPointEntity(10104,12,10082);

    local wolf1 = self:CreateWolfEntity(10105,12,10072);
    wolf1:TurnRight(180);
    -- wolf1:SetCanAutoAttack(false);
    wolf1:SetVisibleRadius(1);
    wolf1:SetDefaultSkillRadius(2);
    wolf1:SetDefaultSkillPeerBlood(10);

    local wolf2 = self:CreateWolfEntity(10084,12,10083);
    wolf2:TurnRight(90);
    wolf2:SetVisibleRadius(1);
    wolf2:SetDefaultSkillRadius(2);
    -- wolf2:SetCanAutoAttack(false);
    wolf2:SetDefaultSkillPeerBlood(10);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddKillEnemyTask(2);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(13, true);

    -- 设置视角
    SetCamera(30, 75, -90);
    SetCameraLookAtBlockPos(10084,12,10072);
end

Level:InitSingleton();
