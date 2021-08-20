
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level8");

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
        <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="34">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="121" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="46">
                <Field label="180" name="angle" value="180"/>
                <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="58">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="121" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="70">
                        <Field label="180" name="angle" value="180"/>
                        <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="82">
                            <Field label="30" name="dist" value="30"/>
                            <Block leftUnitCount="121" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="94">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="106">
                                    <Field label="10" name="dist" value="10"/>
                                    <Block leftUnitCount="121" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="118">
                                        <Field label="180" name="angle" value="180"/>
                                        <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="130">
                                            <Field label="10" name="dist" value="10"/>
                                            <Block leftUnitCount="121" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="142">
                                                <Field label="180" name="angle" value="180"/>
                                                <Block leftUnitCount="121" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="154">
                                                    <Field label="30" name="dist" value="30"/>
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
    self:CreateSunBinEntity(10078,12,10064); 
    self:CreateTianShuCanJuanEntity(10098,12,10104);
    self:CreateGoalPointEntity(10108,12,10094);

    local randomRange = {min = {10093,12,10078}, max = {10095,12,10082}};
    self:CreateWolfEntity(10094,13,10080):SetRandomMove(true, randomRange);
    self:CreateWolfEntity(10094,13,10080):SetRandomMove(true, randomRange);

    local wolf1 = self:CreateWolfEntity(10078,12,10084);
    __run__(function()
        wolf1:SetSpeed(2);
        wolf1:MoveForward(20);
        wolf1:Turn(180);
        while(not wolf1:IsDestory()) do
            print("-------------------------", __get_tick_count__())
            wolf1:MoveForward(30);
            if (wolf1:IsAutoAttacking()) then break end
            wolf1:Turn(180);
            wolf1:MoveForward(30);
            if (wolf1:IsAutoAttacking()) then break end
            wolf1:Turn(180);
        end
    end)

    local wolf2 = self:CreateWolfEntity(10098,12,10084);
    __run__(function()
        wolf2:SetSpeed(2);
        wolf2:Turn(-90);
        wolf2:MoveForward(20);
        wolf2:Turn(180);
        while(not wolf2:IsDestory()) do
            print("-------------------------1", __get_tick_count__())
            wolf2:MoveForward(30);
            if (wolf2:IsAutoAttacking()) then break end
            wolf2:Turn(180);
            wolf2:MoveForward(30);
            if (wolf2:IsAutoAttacking()) then break end
            wolf2:Turn(180);
        end
    end);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(1, true);

    -- -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10081,12,10082);
end

Level:InitSingleton();
