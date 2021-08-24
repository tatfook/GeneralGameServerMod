
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level12");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_BuildAir"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="29">
            <Field label="20" name="dist" value="20"/>
            <Block leftUnitCount="112" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="41">
                <Field label="90" name="angle" value="90"/>
                <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="53">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="65">
                        <Field label="180" name="angle" value="180"/>
                        <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="77">
                            <Field label="10" name="dist" value="10"/>
                            <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="89">
                                <Field label="90" name="angle" value="90"/>
                                <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="101">
                                    <Field label="10" name="dist" value="10"/>
                                    <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="113">
                                        <Field label="180" name="angle" value="180"/>
                                        <Block leftUnitCount="112" type="sunbin_BuildAir" isInputShadowBlock="false" isDraggable="true" topUnitCount="125">
                                            <Block leftUnitCount="112" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="137">
                                                <Field label="180" name="angle" value="180"/>
                                                <Block leftUnitCount="112" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="149">
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
    self:CreateSunBinEntity(10089,12,10065); 
    self:CreateTianShuCanJuanEntity(10079,12,10085);
    local wolf = self:CreateWolfEntity(10099,12,10095);
    wolf:Turn(180);
    -- self:CreateGoalPointEntity(10093,12,10086);
    SetTimeout(15000, function()
        __run__(function()
            wolf:MoveForward(10);
            wolf:TurnLeft(90);
            wolf:MoveForward(30);
        end);
    end);

    SetBlock(10089,11,10076, 126);

    -- 添加任务
    -- self:AddGoalPointTask(1);
    self:AddAliveTimeTask(30);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(11, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10089,12,10073);
end

Level:InitSingleton();
