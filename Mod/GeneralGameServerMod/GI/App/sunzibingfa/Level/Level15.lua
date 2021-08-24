
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level15");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_Attack"/>
        <block type="sunbin_BuildFence"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="38">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="113" type="sunbin_BuildFence" isInputShadowBlock="false" isDraggable="true" topUnitCount="50">
                <Block leftUnitCount="113" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="62">
                    <Field label="180" name="angle" value="180"/>
                    <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="74">
                        <Field label="10" name="dist" value="10"/>
                        <Block leftUnitCount="113" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="86">
                            <Block leftUnitCount="113" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="98">
                                <Block leftUnitCount="113" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="110">
                                    <Block leftUnitCount="113" type="sunbin_Attack" isInputShadowBlock="false" isDraggable="true" topUnitCount="122">
                                        <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="134">
                                            <Field label="10" name="dist" value="10"/>
                                            <Block leftUnitCount="113" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="146">
                                                <Field label="90" name="angle" value="90"/>
                                                <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="158">
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
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 摆放角色
    local sunbin = self:CreateSunBinEntity(10089,12,10073); 
    sunbin:TurnLeft(90);
    sunbin:AddAttackType("wolf");
    self:CreateTianShuCanJuanEntity(10099,12,10063);
    -- self:CreateGoalPointEntity(10093,12,10086);

    local wolf1 = self:CreateWolfEntity(10067,12,10073);
    local wolf2 = self:CreateWolfEntity(10066,12,10073);
    local wolf3 = self:CreateWolfEntity(10100,12,10073);
    local wolf4 = self:CreateWolfEntity(10101,12,10073);
    wolf3:Turn(180);
    wolf4:Turn(180);
    wolf1:SetSpeed(1);
    wolf2:SetSpeed(1);
    wolf3:SetSpeed(1);
    wolf4:SetSpeed(1);

    wolf1:SetVisibleRadius(1);
    wolf2:SetVisibleRadius(1);
    -- wolf3:SetVisibleRadius(1);
    -- wolf4:SetVisibleRadius(1);
    
    wolf1:SetDefaultSkillPeerBlood(10);
    wolf2:SetDefaultSkillPeerBlood(10);
    wolf3:SetDefaultSkillPeerBlood(10);
    wolf4:SetDefaultSkillPeerBlood(10);

    -- 添加任务
    -- self:AddGoalPointTask(1);
    self:AddAliveTimeTask(20);
    self:AddKillEnemyTask(2);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(11, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10089,12,10070);

    __run__(function()
        wolf1:MoveForward(10);
        __run__(function()
            wolf3:MoveForward(20);
        end);
        wolf1:SetVisibleRadius(15);
        wolf1:MoveForward(10);
    end);
    __run__(function()
        wolf2:MoveForward(10);
        __run__(function()
            wolf4:MoveForward(20);
        end);
        wolf2:SetVisibleRadius(15);
        wolf2:MoveForward(10);
    end);
end

Level:InitSingleton();
