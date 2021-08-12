
--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level = inherit(require("%gi%/App/sunzibingfa/Level/Level.lua"), module());

function Level:ctor()
    self:SetLevelName("_level1");

    self:SetToolBoxXmlText([[
<toolbox>
    <category name="运动">
        <block type="sunbin_MoveForward"/>
    </category>
</toolbox>
    ]]);

    self:SetPassLevelXmlText([[
    <Blockly offsetY="0" offsetX="0">
        <Block leftUnitCount="159" type="sunbin_MoveForward" isInputShadowBlock="false" isDraggable="true" topUnitCount="83">
            <Field label="20" name="dist" value="20"/>
        </Block>
        <ToolBox category="运动" offset="0"/>
    </Blockly>
    ]]);
end

-- 加载关卡
function Level:LoadLevel()
    Level._super.LoadLevel(self);

    -- 创建角色
    self:CreateSunBinEntity(10090,12,10067); 
    self:CreateTianShuCanJuanEntity(10090,12,10077);
    self:CreateGoalPointEntity(10090,12,10087);
    self:CreatePangJuanEntity(10090,12,10089);
    
    -- 添加任务
    self:AddPassLevelTask(self.GOODS_ID.GOAL_POINT, 1);
    self:AddPassLevelExtraTask(self.GOODS_ID.TIAN_SHU_CAN_JUAN, 1);

    -- 调整场景
    SetCamera(30, 75, -90);
    SetCameraLookAtBlockPos(10090,12,10077);
end

-- 代码执行前 默认完成场景重置操作
function Level:RunLevelCodeBefore()
    Level._super.RunLevelCodeBefore(self);
end

--  代码执行完成 默认完成检测主玩家是否到达指定地点
function Level:RunLevelCodeAfter()
    Level._super.RunLevelCodeAfter(self);
    -- 可在此自定义通关逻辑  默认到达目标点
end

-- 编辑旧关卡
function Level:EditOld()
    Level._super:EditOld("level1");
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