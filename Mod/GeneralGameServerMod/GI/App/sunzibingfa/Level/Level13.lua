
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level13");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_BuildBridge"/>
        <block type="sunbin_BuildAir"/>
        </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[

        <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="117" type="sunbin_BuildBridge" isInputShadowBlock="false" isDraggable="true" topUnitCount="25">
            <Block leftUnitCount="117" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="37">
                <Field label="90" name="angle" value="90"/>
                <Block leftUnitCount="117" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="49">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="117" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="61">
                        <Field label="90" name="angle" value="90"/>
                        <Block leftUnitCount="117" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="73">
                            <Field label="10" name="dist" value="10"/>
                            <Block leftUnitCount="117" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="85">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="117" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="97">
                                    <Field label="10" name="dist" value="10"/>
                                    <Block leftUnitCount="117" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="109">
                                        <Field label="90" name="angle" value="90"/>
                                        <Block leftUnitCount="117" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="121">
                                            <Field label="20" name="dist" value="20"/>
                                            <Block leftUnitCount="117" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="133">
                                                <Field label="90" name="angle" value="90"/>
                                                <Block leftUnitCount="117" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="145">
                                                    <Field label="20" name="dist" value="20"/>
                                                    <Block leftUnitCount="117" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="157">
                                                        <Field label="90" name="angle" value="90"/>
                                                        <Block leftUnitCount="117" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="169">
                                                            <Field label="3" name="dist" value="3"/>
                                                            <Block leftUnitCount="117" type="sunbin_BuildAir" isInputShadowBlock="false" isDraggable="true" topUnitCount="181">
                                                                <Block leftUnitCount="117" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="193">
                                                                    <Field label="180" name="angle" value="180"/>
                                                                    <Block leftUnitCount="117" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="205">
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
    local sunbin = self:CreateSunBinEntity(10094,12,10084); 
    sunbin:Turn(180);
    sunbin:SetSpeed(2);

    self:CreateTianShuCanJuanEntity(10084,12,10074);

    local hunter = self:CreateHunterEntity(10094,12,10080);

    hunter:SetCanAutoAttack(false);
    hunter:TurnRight(90);
    hunter:SetSpeed(2);

    SetBlock(10094,11,10075, 126);
    SetBlock(10094,11,10083, 126);
    SetBlock(10075,11,10094, 126);
    
  
    local wolf = self:CreateWolfEntity(10094,12,10074);
    wolf:TurnLeft(90);
    wolf:SetVisibleRadius(8);
    wolf:AddAttackType("hunter");
    -- wolf:SetSpeed(1.8);
    -- self:CreateGoalPointEntity(10093,12,10086);

    -- 添加任务
    -- self:AddGoalPointTask(1);
    self:AddKillEnemyTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(16, true);

    -- 设置视角
    SetCamera(40, 60, -90);
    SetCameraLookAtBlockPos(10094,12,10080);

    -- 猎人
    __run__(function()
        local blockId = GetBlockId(10094,11,10083);
        while(blockId == 0) do sleep() end
        hunter:Turn(180);
        hunter:MoveForward(4);
        hunter:TurnRight(90);
        hunter:MoveForward(10);
        hunter:TurnLeft(90);
        hunter:MoveForward(10);
        hunter:TurnLeft(90);
        hunter:MoveForward(20);
        hunter:TurnLeft(90);
        hunter:MoveForward(10);
        hunter:TurnLeft(90);
        hunter:MoveForward(10);
        hunter:TurnRight(90);
        hunter:MoveForward(10);
        hunter:SetCanAutoAttack(true);
    end);

    wolf:UpdatePosition(true);

    -- 狼
    -- __run__(function()
    -- end);
end

Level:InitSingleton();
