
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
    -- self:CreateWolfEntity(10094,13,10080):SetRandomMove(true, randomRange);
    -- self:CreateWolfEntity(10094,13,10080):SetRandomMove(true, randomRange);
    -- self:CreateWolfEntity(10094,13,10080):SetRandomMove(true, randomRange);

    local wolf1 = self:CreateWolfEntity(10068,12,10084);
    __run__(function()
        while(not wolf1:IsDestory()) do
            wolf1:MoveForward(30);
            if (self:IsAutoAttacking()) then break end
            wolf1:Turn(180);
            wolf1:MoveForward(30);
            if (self:IsAutoAttacking()) then break end
            wolf1:Turn(180);
        end
    end)

    -- 添加任务
    self:AddGoalPointTask(1);
    self:AddTianShuCanJuanTask(1, true);
    self:AddCodeLineTask(1, true);

    -- -- 设置视角
    SetCamera(40, 75, -90);
    SetCameraLookAtBlockPos(10081,12,10082);
end

Level:InitSingleton();
