
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level18");

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
        <Block leftUnitCount="148" type="while_true" isInputShadowBlock="false" isDraggable="true" topUnitCount="64">
            <Input label="" name="statement" value="">
                <Block leftUnitCount="152" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="75">
                    <Field label="10" name="dist" value="10"/>
                    <Block leftUnitCount="152" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="87">
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
    local sunbin = self:CreateSunBinEntity(10077,12,10073); 
    self:CreateTianShuCanJuanEntity(10087,12,10073);
    local interval = math.floor(10 *__BlockSize__ / sunbin:GetStepDistance() * __get_tick_timestamp__() / 6);
    local arrow_tower1 = self:CreateArrowTowerEntity(10082,12,10078);
    arrow_tower1:Turn(45);
    arrow_tower1:SetAttackInterval(interval);
    local arrow_tower2 = self:CreateArrowTowerEntity(10092,12,10078);
    arrow_tower2:Turn(135);
    arrow_tower2:SetAttackInterval(interval);

    local last_tick_count = __get_tick_count__();
    local last_timestamp = __get_timestamp__();
    __run__(function()
        while(not arrow_tower1:IsDestory() and not arrow_tower2:IsDestory() and self:IsPlaying() and __is_running__()) do
            arrow_tower1:Turn(15);
            arrow_tower1:Attack();
            arrow_tower2:Turn(15);
            arrow_tower2:Attack();
            sleep(interval);
        end
    end);
    -- 添加任务
    self:AddAliveTimeTask(60);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(3, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10087,12,10078);
end

Level:InitSingleton();
