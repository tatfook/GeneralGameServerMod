
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level22");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_BuildBridge"/>
        <block type="sunbin_Attack"/>
    </category>
    <category name="控制">
        <block type="while_true"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[

        <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="117" type="while_true" isInputShadowBlock="false" isDraggable="true" topUnitCount="24">
            <Input label="" name="statement" value="">
                <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="35">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="121" type="sunbin_BuildBridge" isInputShadowBlock="false" isDraggable="true" topUnitCount="47">
                        <Block leftUnitCount="121" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="59">
                            <Field label="180" name="angle" value="180"/>
                            <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="71">
                                <Field label="10" name="dist" value="10"/>
                                <Block leftUnitCount="121" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="83">
                                    <Field label="180" name="angle" value="180"/>
                                    <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="95">
                                        <Field label="20" name="dist" value="20"/>
                                        <Block leftUnitCount="121" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="107">
                                            <Field label="180" name="angle" value="180"/>
                                            <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="119">
                                                <Field label="10" name="dist" value="10"/>
                                                <Block leftUnitCount="121" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="131">
                                                    <Field label="90" name="angle" value="90"/>
                                                    <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="143">
                                                        <Field label="10" name="dist" value="10"/>
                                                        <Block leftUnitCount="121" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="155">
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
    self:CreateSunBinEntity(10081,12,10065); 

    self:CreateTianShuCanJuanEntity(10081,12,10085);
    -- self:CreateWolfEntity(10081,12,10086):SetVisibleRadius(0.5);
    self:CreateTianShuCanJuanEntity(10091,12,10095);
    -- self:CreateWolfEntity(10091,12,10096):SetVisibleRadius(0.5);
    self:CreateTianShuCanJuanEntity(10101,12,10105);
    -- self:CreateWolfEntity(10101,12,10106):SetVisibleRadius(0.5);
    self:CreateGoalPointEntity(10111,12,10095);
    
    self:CreateWolfEntity(10086,12,10087):Turn(90):SetVisibleRadius(1);
    self:CreateWolfEntity(10087,12,10087):Turn(90):SetVisibleRadius(1);
    self:CreateWolfEntity(10096,12,10097):Turn(90):SetVisibleRadius(1);
    self:CreateWolfEntity(10097,12,10097):Turn(90):SetVisibleRadius(1);

    local wolf1 = self:CreateWolfEntity(10081,12,10075);
    __run__(function()
        wolf1:SetSpeed(1);
        wolf1:Turn(180);
        wolf1:SetVisibleRadius(1);
        wolf1:MoveForward(10);
        while(self:IsPlaying() and not wolf1:IsDestory() and not wolf1:IsAutoAttacking()) do
            wolf1:Turn(180);
            wolf1:MoveForward(20);
        end
    end);
    local wolf2 = self:CreateWolfEntity(10091,12,10085);
    __run__(function()
        wolf2:SetSpeed(1);
        -- wolf2:Turn(180);
        wolf2:SetVisibleRadius(1);
        wolf2:MoveForward(10);
        while(self:IsPlaying() and not wolf2:IsDestory() and not wolf2:IsAutoAttacking()) do
            wolf2:Turn(180);
            wolf2:MoveForward(20);
        end
    end);

    local wolf3 = self:CreateWolfEntity(10101,12,10095);
    __run__(function()
        wolf3:SetSpeed(1);
        wolf3:Turn(180);
        wolf3:SetVisibleRadius(1);
        wolf3:MoveForward(10);
        while(self:IsPlaying() and not wolf3:IsDestory() and not wolf3:IsAutoAttacking()) do
            wolf3:Turn(180);
            wolf3:MoveForward(20);
        end
    end);
    
    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(3, true);
    self:AddCodeLineTask(12, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10085,12,10075);
end

Level:InitSingleton();
