--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Task = require("Task");
local Level = inherit(require("Level"), module()) ;

Level:Property("Speed");                            -- 倍速
Level:Property("Passed", false, "IsPassed");        -- 是否已通过
Level.GOODS_ID = {
    GOAL_POINT = "goalpoint",
    TIAN_SHU_CAN_JUAN = "tianshucanjuan",
}

function Level:ctor()
    self.__all_entity__ = {};
    self.__task__ = Task:new();
    self:SetPassed(false);
end

function Level:AddPassLevelTask(gsid, count)
    self.__task__:AddTaskItem(gsid, count);
end

function Level:AddPassLevelExtraTask(gsid, count)
    self.__task__:AddExtraTaskItem(gsid, count);
end

-- 监听关卡加载事件,  完成关卡内容设置
function Level:LoadLevel()
    Level._super.LoadLevel(self);
    
    self.__task__:Clear();
    for _, entity in pairs(self.__all_entity__) do
        entity:Destroy();
    end
end

-- 监听关卡卸载事件,  移除关卡相关资源
function Level:UnloadLevel()
    Level._super.UnloadLevel(self);
end

-- 执行关卡代码前, 
function Level:RunLevelCodeBefore()
    Level._super.RunLevelCodeBefore(self);
    if (not self.__sunbin__) then return end
    self.__sunbin__:SetSpeed(self:GetSpeed());
end

-- 检测是否通关
function Level:CheckPassLevel()
    if (not self.__sunbin__) then return end
    if (self:IsPassed()) then return end 
    
    -- 更新任务列表
    for _, goods in pairs(self.__sunbin__:GetAllGoods()) do
        self.__task__:SetTaskItemCount(goods:GetGoodsID(), goods:GetStackCount());
    end
    
    -- TODO 刷新UI

    -- 是否到达目标点
    if (self.__task__:IsFinishGoal()) then
        self.__sunbin__:Stop();  -- 停止移动
        self:PassLevel();
    end
end

-- 执行关卡代码后
function Level:RunLevelCodeAfter()
    Level._super.RunLevelCodeAfter(self);
    self:CheckPassLevel();
end

-- 重置关卡
function Level:ResetLevel()
    Level._super.ResetLevel(self);
end

-- 通关
function Level:PassLevel()
    if (self:IsPassed()) then return end
    Tip("通过关卡");
    self:SetPassed(true);
end

-- 编辑旧关卡 后续废弃
function Level:EditOld(level_name)
    Level._super.Edit(self);
    self:UnloadMap();
    cmd("/property UseAsyncLoadWorld false")
    cmd("/property AsyncChunkMode false");
    if (level_name and level_name ~= "") then cmd(format("/loadtemplate 10064 12 10064 %s", level_name)) end
    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");
    cmd(format("/goto %s %s %s", 10064, 8, 10064));
end

-- 编辑
function Level:Edit()
    Level._super.Edit(self);
end

-- 创建孙膑NPC
function Level:CreateSunBinEntity(bx, by, bz)
    local sunbin = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "sunbin",
        biped = true,
        assetfile = "character/CC/artwar/game/sunbin.x",
        physicsHeight = 1.765,
    });
    sunbin:TurnLeft(90);
    sunbin:SetGoodsChangeCallBack(function()
        self:CheckPassLevel();
    end)
    self.__all_entity__["sunbin"] = sunbin;
    self.__sunbin__ = sunbin;
    return sunbin;
end

-- 创建天书残卷NPC
function Level:CreateTianShuCanJuanEntity(bx, by, bz)
    local fireglowingcircle = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "fireglowingcircle",
        assetfile = "character/CC/05effect/fireglowingcircle.x",
    });
    self.__all_entity__["fireglowingcircle"] = fireglowingcircle;

    fireglowingcircle:AddGoods(CreateGoods({dead = true}));
    local tianshucanjuan = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "tianshucanjuan",
        assetfile = "@/blocktemplates/tianshucanjuan.x",
    });
    self.__all_entity__["tianshucanjuan"] = tianshucanjuan;
    tianshucanjuan:AddGoods(CreateGoods({dead = true}));
    tianshucanjuan:AddGoods(CreateGoods({gsid = self.GOODS_ID.TIAN_SHU_CAN_JUAN, transfer = true, title = "天书残卷", description = "荣誉物品"}));
    tianshucanjuan:SetPositionChangeCallBack(function()
        fireglowingcircle:SetPosition(tianshucanjuan:GetPosition())
    end);
    return tianshucanjuan;
end

-- 创建庞涓NPC
function Level:CreatePangJuanEntity(bx, by, bz)
    local pangjuan = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "pangjuan",
        assetfile = "character/CC/artwar/game/pangjuan.x",
    });
    pangjuan:Turn(90);
    self.__all_entity__["pangjuan"] = pangjuan;
    return pangjuan;
end

-- 创建目标位置NPC
function Level:CreateGoalPointEntity(bx, by, bz)
    local goalpoint = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "goalpoint",
        -- assetfile = "@/blocktemplates/goalpoint.bmax",
        assetfile = "character/CC/05effect/fireglowingcircle.x",
    });
    self.__all_entity__["goalpoint"] = goalpoint;
    goalpoint:AddGoods(CreateGoods({gsid = self.GOODS_ID.GOAL_POINT, title = "目标位置", description = "角色到达指定地点获得该物品", transfer = true}));
    return goalpoint;
end

Level:InitSingleton();



-- -- 监听关卡加载事件,  完成关卡内容设置
-- On("LoadLevel", function()
-- end);

-- -- 监听关卡卸载事件,  移除关卡相关资源
-- On("UnloadLevel", function()
-- end)

-- -- 执行关卡代码前, 
-- On("RunLevelCodeBefore", function()
-- end)

-- -- 执行关卡代码后
-- On("RunLevelCodeAfter", function()
-- end)

-- -- 重置关卡
-- On("ResetLevel", function()
-- end);

-- -- 触发关卡重置
-- Emit("ResetLevel");