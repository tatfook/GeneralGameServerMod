
--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level = inherit(require("%gi%/App/sunzibingfa/Level/Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level3");

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
        <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="43">
            <Field label="20" name="dist" value="20"/>
            <Block leftUnitCount="113" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="55">
                <Field label="180" name="angle" value="180"/>
                <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="67">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="113" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="79">
                        <Field label="90" name="angle" value="90"/>
                        <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="91">
                            <Field label="10" name="dist" value="10"/>
                            <Block leftUnitCount="113" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="103">
                                <Field label="180" name="angle" value="180"/>
                                <Block leftUnitCount="113" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="115">
                                    <Field label="20" name="dist" value="20"/>
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

    -- self:SetWorkspaceXmlText(self:GetPassLevelXmlText());
    -- self:SetSpeed(5);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    self:CreateSunBinEntity(10087,12,10065); 
    self:CreateTianShuCanJuanEntity(10087,12,10085);
    self:CreateGoalPointEntity(10077,12,10075);
    self:CreateGoalPointEntity(10097,12,10075);

    -- 添加任务
    self:AddPassLevelTask(self.GOODS_ID.GOAL_POINT, 2);
    self:AddPassLevelExtraTask(self.GOODS_ID.TIAN_SHU_CAN_JUAN, 1);
    self:AddPassLevelExtraTask(self.GOODS_ID.CODE_LINE, 5);

    SetCamera(30, 75, -90);
    SetCameraLookAtBlockPos(10087,11,10071);
end

-- 编辑旧关卡
function Level:EditOld()
    Level._super:EditOld("level3");
end

-- 关卡编辑
function Level:Edit()
    Level._super.Edit(self);
    -- self:UnloadMap();
    -- cmd("/loadtemplate 10064 12 10064 level1.1");
    self:LoadLevel();
    -- cmd(format("/goto %s %s %s", 10090,12,10077));
end

Level:InitSingleton();
