
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level16");

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
        <Block leftUnitCount="123" type="while_true" isInputShadowBlock="false" isDraggable="true" topUnitCount="61">
            <Input label="" name="statement" value="">
                <Block leftUnitCount="127" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="72">
                    <Field label="20" name="dist" value="20"/>
                    <Block leftUnitCount="127" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="84">
                        <Field label="90" name="angle" value="90"/>
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
    self:CreateSunBinEntity(10079,12,10067); 
    self:CreateLiangShiEntity(10079,12,10072);
    self:CreateLiangShiEntity(10084,12,10087);
    self:CreateLiangShiEntity(10094,12,10067);
    self:CreateLiangShiEntity(10099,12,10082);
    self:CreateTianShuCanJuanEntity(10099,12,10077);
    self:CreateTianShuCanJuanEntity(10089,12,10087);
    -- self:CreateGoalPointEntity(10093,12,10086);

    -- 添加任务
    self:AddLiangShiTask(4);
    self:AddTianShuCanJuanTask(2, true);
    self:AddCodeLineTask(3, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10087,12,10073);
end

Level:InitSingleton();
