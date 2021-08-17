
--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level = inherit(require("%gi%/App/sunzibingfa/Level/Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level1.1");

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
        <Block leftUnitCount="141" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="84">
            <Field label="10" name="dist" value="10"/>
            <Block leftUnitCount="141" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="96">
                <Field label="90" name="angle" value="90"/>
                <Block leftUnitCount="141" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="108">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="141" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="120">
                        <Field label="90" name="angle" value="90"/>
                        <Block leftUnitCount="141" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="132">
                            <Field label="10" name="dist" value="10"/>
                        </Block>
                    </Block>
                </Block>
            </Block>
        </Block>
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);
end

function Level:LoadLevel()
    Level._super.LoadLevel(self);

    self:CreateSunBinEntity(10093,12,10064);
    self:CreateTianShuCanJuanEntity(10083,12,10074);
    self:CreateGoalPointEntity(10083,12,10084);

    -- 添加任务
    self:AddPassLevelTask(self.GoodsConfig.GOAL_POINT.ID, 1);
    self:AddPassLevelExtraTask(self.GoodsConfig.TIAN_SHU_CAN_JUAN.ID, 1);

    SetCamera(30, 75, -90);
    SetCameraLookAtBlockPos(10093,12,10074);
end

function Level:RunLevelCodeBefore()
    Level._super.RunLevelCodeBefore(self);
    if (not self.__sunbin__) then return end
    -- self.__sunbin__:SetSpeed(5);
end

--  代码执行完成
function Level:RunLevelCodeAfter()
    Level._super.RunLevelCodeAfter(self);
    -- 可在此自定义通关逻辑  默认到达目标点
end

-- 编辑旧关卡
function Level:EditOld()
    Level._super:EditOld("level1");
end

function Level:Edit()
    Level._super.Edit(self);
    self:LoadLevel();
    cmd(format("/goto %s %s %s", 10090,13,10064));
end

Level:InitSingleton();
