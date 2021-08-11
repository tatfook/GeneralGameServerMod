--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Task = require("Task");
local Level = inherit(require("Level"), module()) ;

Level:Property("PassLevelState", 0);        -- 0 初始态 1 通关 2 失败
Level.GOODS_ID = {
    GOAL_POINT = "goalpoint",
    TIAN_SHU_CAN_JUAN = "tianshucanjuan",
    CODE_LINE = "codeline",
    MAX_ALIVE_TIME = "max_alive_time",
}

Level.GOODS = {
    [Level.GOODS_ID.GOAL_POINT] = {
        title = "目标点",
        task_title = "达到目的地",
    },
    [Level.GOODS_ID.TIAN_SHU_CAN_JUAN] = {
        title = "天书残卷",
        task_title = "收集天书残卷",
    },
    [Level.GOODS_ID.CODE_LINE] = {
        title = "代码行",
        task_title = "代码行数少于",
        task_description = nil,
        task_reverse_compare = true,
    },
    [Level.GOODS_ID.MAX_ALIVE_TIME] = {
        title = "最长存活时间",
        task_title = "完成时间少于",
        task_reverse_compare = true,
    }
}

function Level:ctor()
    self.__all_entity__ = {};
    self.__all_timer__ = {};
    self.__task__ = Task:new();
    self:SetPassed(false);
end

function Level:AddPassLevelTask(gsid, count, title, description)
    local goods = self.GOODS[gsid];
    self.__task__:AddTaskItem(gsid, count, goods and goods.task_title, goods and goods.task_description, goods and goods.task_reverse_compare);
end

function Level:AddPassLevelExtraTask(gsid, count, title, description)
    local goods = self.GOODS[gsid];
    self.__task__:AddExtraTaskItem(gsid, count, goods and goods.task_title, goods and goods.task_description, goods and goods.task_reverse_compare);
end

-- 监听关卡加载事件,  完成关卡内容设置
function Level:LoadLevel()
    self:UnloadLevel();

    Level._super.LoadLevel(self);
    
    self.__task__:ShowUI();
end

-- 监听关卡卸载事件,  移除关卡相关资源
function Level:UnloadLevel()
    Level._super.UnloadLevel(self);

    self:SetPassLevelState(0);
    self.__task__:Clear();
    self.__task__:CloseUI();
    for _, entity in pairs(self.__all_entity__) do
        entity:Destroy();
    end
end

-- 执行关卡代码前, 
function Level:RunLevelCodeBefore()
    Level._super.RunLevelCodeBefore(self);
    if (not self.__sunbin__) then return end
    self.__sunbin__:SetSpeed(self:GetSpeed());
    self.__task__:SetTaskItemCount(self.GOODS_ID.CODE_LINE, self:GetStatementBlockCount());
end

-- 检测是否通关
function Level:CheckPassLevel()
    if (not self.__sunbin__) then return end
    if (self:GetPassLevelState() ~= 0) then return end 
    
    -- 更新任务列表
    for _, goods in pairs(self.__sunbin__:GetAllGoods()) do
        self.__task__:SetTaskItemCount(goods:GetGoodsID(), goods:GetStackCount());
    end
    
    -- TODO 刷新UI

    -- 是否到达目标点
    if (self.__task__:IsFinishGoal()) then
        self:PassLevelSuccess();
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
function Level:PassLevelSuccess()
    if (self:GetPassLevelState() ~= 0) then return end 
    -- 停止移动
    if (self.__sunbin__) then self.__sunbin__:Stop() end 
    self:SetPassLevelState(1);
    Tip("通过成功");
end

-- 通关失败
function Level:PassLevelFailed()
    if (self:GetPassLevelState() ~= 0) then return end 
    -- 停止移动
    if (self.__sunbin__) then self.__sunbin__:Stop() end 
    self:SetPassLevelState(2);
    Tip("通过失败");
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
    end);
    sunbin:SetDestroyCallBack(function()
        self:PassLevelFailed();
    end);
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