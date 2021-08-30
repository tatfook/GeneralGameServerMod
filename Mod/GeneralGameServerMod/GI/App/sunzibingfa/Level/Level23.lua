
--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡文件
use the lib:
]]

local Level = inherit(require("./Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level23");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
        <block type="sunbin_TurnLeft"/>
        <block type="sunbin_TurnRight"/>
        <block type="sunbin_BuildFence"/>
    </category>
    <category name="控制">
        <block type="while_true"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="120" type="while_true" isInputShadowBlock="false" isDraggable="true" topUnitCount="55">
            <Input label="" name="statement" value="">
                <Block leftUnitCount="124" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="66">
                    <Field label="90" name="angle" value="90"/>
                    <Block leftUnitCount="124" type="sunbin_BuildFence" isInputShadowBlock="false" isDraggable="true" topUnitCount="78">
                        <Block leftUnitCount="124" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="90">
                            <Field label="180" name="angle" value="180"/>
                            <Block leftUnitCount="124" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="102">
                                <Field label="10" name="dist" value="10"/>
                                <Block leftUnitCount="124" type="sunbin_TurnLeft" isInputShadowBlock="false" isDraggable="true" topUnitCount="114">
                                    <Field label="180" name="angle" value="180"/>
                                    <Block leftUnitCount="124" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="126">
                                        <Field label="10" name="dist" value="10"/>
                                        <Block leftUnitCount="124" type="sunbin_TurnRight" isInputShadowBlock="false" isDraggable="true" topUnitCount="138">
                                            <Field label="90" name="angle" value="90"/>
                                            <Block leftUnitCount="124" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="150">
                                                <Field label="10" name="dist" value="10"/>
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
    self:CreateSunBinEntity(10089,12,10069); 
    self:CreateTianShuCanJuanEntity(10099,12,10079); 
    self:CreateTianShuCanJuanEntity(10099,12,10089); 
    self:CreateTorchEntity(10099,12,10069);
    self:CreateGoalPointEntity(10099,11,10099);

    self:CreateWolfEntity(10096,12,10079):Turn(180):SetVisibleRadius(2);  
    self:CreateWolfEntity(10096,12,10089):Turn(180):SetVisibleRadius(2);  
    local trap_pos_list = {{10097,12,10079}, {10097,12,10089}};
    for _, pos in ipairs(trap_pos_list) do
        self:CreateTrapEntity(pos[1], pos[2], pos[3]);
        self:CreateTrapEntity(pos[1] - 1, pos[2], pos[3] - 1);
        self:CreateTrapEntity(pos[1] - 1, pos[2], pos[3] + 1);
        self:CreateTrapEntity(pos[1] + 1, pos[2], pos[3] - 1);
        self:CreateTrapEntity(pos[1] + 1, pos[2], pos[3] + 1);
    end

    local tiger = self:CreateTigerEntity(10079,12,10069);
    tiger:SetVisibleRadius(20);
    tiger:SetSpeed(1);

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(2, true);
    self:AddCodeLineTask(9, true);

    -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10089,12,10076);
end

Level:InitSingleton();

-- 老虎的逻辑怎么写???