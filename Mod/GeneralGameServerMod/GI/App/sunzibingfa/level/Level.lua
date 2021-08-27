--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡基类文件
use the lib:
]]

require("../Entity/EntityAPI.lua");

local GoodsConfig = require("../GoodsConfig.lua");
local API = require("./API.lua");
local Task = require("Task");
local Level = inherit(require("Level"), module()) ;

Level.GoodsConfig = GoodsConfig;
Level:Property("LevelState", 0);        -- 0 初始态 1 开始 2 通关 3 失败

Level.STATE = {
    INIT = 0,
    PLAYING = 1,
    SUCCESS = 2,
    FAILED = 3,
}

function Level:ctor()
    self.__all_entity__ = {};
    self.__all_timer__ = {};
    self.__task__ = Task:new();
    self:SetLevelState(0);
end

----------------------------------------------task api----------------------------------------------
function Level:AddTaskItem(gsid, count, title, description)
    local goods = GoodsConfig[gsid];
    local TaskItemName = string.format("Add%sTaskItem", goods and goods.task_item or "");
    return (self.__task__[TaskItemName])(self.__task__, gsid, count, goods and goods.task_title, goods and goods.task_description, goods and goods.task_reverse_compare);
end

function Level:AddExtraTaskItem(gsid, count, title, description)
    local goods = GoodsConfig[gsid];
    local TaskItemName = string.format("Add%sExtraTaskItem", goods and goods.task_item or "");
    return (self.__task__[TaskItemName])(self.__task__, gsid, count, goods and goods.task_title, goods and goods.task_description, goods and goods.task_reverse_compare);
end

function Level:GetTaskItemCount(gsid)
    return self.__task__:GetTaskItemCount(gsid);
end

function Level:SetTaskItemCount(gsid, count)
    self.__task__:SetTaskItemCount(gsid, count);
end

function Level:__AddTaskItem__(bIsExtraTask, ...)
    if (bIsExtraTask) then
        self:AddExtraTaskItem(...);
    else 
        self:AddTaskItem(...);
    end
end

function Level:AddGoalPointTask(goal_count, bIsExtraTask)
    self:__AddTaskItem__(bIsExtraTask, GoodsConfig.GOAL_POINT.ID, goal_count);
end

function Level:AddTianShuCanJuanTask(goal_count, bIsExtraTask)
    self:__AddTaskItem__(bIsExtraTask, GoodsConfig.TIAN_SHU_CAN_JUAN.ID, goal_count);
end

function Level:AddCodeLineTask(goal_count, bIsExtraTask)
    self:__AddTaskItem__(bIsExtraTask, GoodsConfig.CODE_LINE.ID, goal_count);
end

function Level:AddKillEnemyTask(goal_count, bIsExtraTask)
    self:__AddTaskItem__(bIsExtraTask, GoodsConfig.KILL_ENEMY.ID, goal_count);
end

function Level:AddLiangShiTask(goal_count, bIsExtraTask)
    self:__AddTaskItem__(bIsExtraTask, GoodsConfig.LIANG_SHI.ID, goal_count);
end

function Level:AddAliveTimeTask(goal_count, bIsExtraTask)
    if (bIsExtraTask) then
        self:AddExtraTaskItem(GoodsConfig.ALIVE_TIME.ID, goal_count)
    else 
        local taskitem = self:AddTaskItem(GoodsConfig.ALIVE_TIME.ID, goal_count);
        taskitem:SetFinishCallBack(function()
            self:PassLevelSuccess();
            taskitem:Stop();
        end);
    end
end

function Level:IsPlaying()
    return self:GetLevelState() == self.STATE.PLAYING;
end

-- 监听关卡加载事件,  完成关卡内容设置
function Level:LoadLevel()
    self:UnloadLevel();

    Level._super.LoadLevel(self);
    
    self:SetLevelState(self.STATE.PLAYING);
    self.__task__:ShowUI();
    self:ShowCameraUI();
    self.__timer__ = SetInterval(1000, function()
        -- 是否到达目标点
        if (self.__task__:IsFinishGoal()) then
            self:PassLevelSuccess();
        end
        if (self:GetLevelState() ~= self.STATE.PLAYING) then
            self.__timer__:Stop();
        end
    end);
end

-- 监听关卡卸载事件,  移除关卡相关资源
function Level:UnloadLevel()
    Level._super.UnloadLevel(self);

    self:SetLevelState(self.STATE.INIT);
    self.__task__:Clear();
    self.__task__:CloseUI();
    self:CloseCameraUI();
    
    for _, entity in pairs(self.__all_entity__) do
        entity:Destroy();
    end

    if (self.__timer__) then
        self.__timer__:Stop();
        self.__timer__ = nil;
    end
end

-- 重置关卡
function Level:ResetLevel()
    Level._super.ResetLevel(self);
end

function Level:BuildEnv()
    local CodeEnv = self:GetCodeEnv();
    CodeEnv.sunbin = self.__sunbin__;
    for key, val in pairs(API) do CodeEnv[key] = val end 
    CodeEnv.SetG(CodeEnv);
    CodeEnv.SetLevel(self);
end

-- 执行关卡代码前, 
function Level:RunLevelCodeBefore()
    Level._super.RunLevelCodeBefore(self);
    if (not self.__sunbin__) then return end
    __set_tick_speed__(self:GetSpeed());
    self.__task__:SetTaskItemCount(GoodsConfig.CODE_LINE.ID, self:GetStatementBlockCount());
    self:BuildEnv();
end

-- 执行关卡代码后
function Level:RunLevelCodeAfter()
    Level._super.RunLevelCodeAfter(self);
    -- 是否到达目标点
    if (self.__task__:IsFinishGoal()) then
        self:PassLevelSuccess();
    end
end

-- 检测是否通关
function Level:CheckPassLevel()
    if (not self.__sunbin__ or self:GetLevelState() ~= self.STATE.PLAYING) then return end 
    
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

-- 通关
function Level:PassLevelSuccess()
    if (self:GetLevelState() ~= self.STATE.PLAYING) then return end 
    self:StopRunCode();
    if (self.__sunbin__) then self.__sunbin__:SetAnimId(0) end 
    self:SetLevelState(self.STATE.SUCCESS);
    Tip("通过成功");
end

-- 通关失败
function Level:PassLevelFailed()
    if (self:GetLevelState() ~= self.STATE.PLAYING) then return end 
    self:StopRunCode();
    if (self.__sunbin__) then self.__sunbin__:SetAnimId(0) end 
    self:SetLevelState(self.STATE.FAILED);
    Tip("通过失败");
end

-- 编辑
function Level:Edit(...)
    Level._super.Edit(self, ...);
end

-- 显示相机UI
function Level:ShowCameraUI()
    self.__camera_ui__ = ShowWindow({
        OnDefaultView = function()
            self:ResetLevel();
        end,
        OnZoomIn = function()
            SetCameraObjectDistance(math.max(GetCameraObjectDistance() - 2, 6)); 
        end,
        OnZoomOut = function()
            SetCameraObjectDistance(math.min(GetCameraObjectDistance() + 2, 50)); 
        end,
    }, {
        template = [[
<template style="display: flex; background-color:#00000000;color:#eeeeee;font-size:14px;margin:5px;">
    <div style="width:30px; height:30px;background:url(@/textures/resetView.png); margin:5px;"  tooltip="恢复默认视角" onclick="OnDefaultView"></div>
    <div style="width:30px; height:30px;background:url(@/textures/zoomIn.png); margin:5px;"  tooltip="放大视角" onclick="OnZoomIn"></div>
    <div style="width:30px; height:30px;background:url(@/textures/zoomOut.png); margin:5px;" tooltip="缩小视角" onclick="OnZoomOut"></div>
</template>
        ]],
        alignment = "_rt",
        width = 120,
        height = 50,
    })
end

function Level:CloseCameraUI()
    if (not self.__camera_ui__) then return end
    self.__camera_ui__:CloseWindow();
    self.__camera_ui__ = nil;
end

-- 创建孙膑NPC
function Level:CreateSunBinEntity(bx, by, bz)
    local sunbin = CreateSunBinEntity(bx, by, bz);
    sunbin:TurnLeft(90);
    sunbin:SetGoodsChangeCallBack(function()
        self:CheckPassLevel();
    end);
    sunbin:SetDestroyCallBack(function()
        self:PassLevelFailed();
    end);
    table.insert(self.__all_entity__, sunbin);
    self.__sunbin__ = sunbin;
    return sunbin;
end

-- 创建天书残卷NPC
function Level:CreateTianShuCanJuanEntity(bx, by, bz)
    local fireglowingcircle = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "fireglowingcircle",
        assetfile = "character/CC/05effect/fireglowingcircle.x",
        destroyBeCollided = true,
        hasBlood = false,
    });
    table.insert(self.__all_entity__, fireglowingcircle);

    local tianshucanjuan = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "tianshucanjuan",
        assetfile = "@/blocktemplates/tianshucanjuan.x",
        hasBlood = false,
        destroyBeCollided = true,
    });
    table.insert(self.__all_entity__, tianshucanjuan);
    tianshucanjuan:AddGoods(CreateGoods({gsid = GoodsConfig.TIAN_SHU_CAN_JUAN.ID, transfer = true, title = "天书残卷", description = "荣誉物品"}));
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
    table.insert(self.__all_entity__, pangjuan);
    return pangjuan;
end

-- 创建目标位置NPC
function Level:CreateGoalPointEntity(bx, by, bz)
    local goalpoint = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "goalpoint",
        -- assetfile = "@/blocktemplates/goalpoint.bmax",
        -- assetfile = "character/CC/05effect/fireglowingcircle.x", 
        assetfile = "character/v5/09effect/TransmittalDoor/TransmittalDoor.x",  

    });
    table.insert(self.__all_entity__, goalpoint);
    goalpoint:AddGoods(CreateGoods({gsid = GoodsConfig.GOAL_POINT.ID, title = "目标位置", description = "角色到达指定地点获得该物品", transfer = true}));
    return goalpoint;
end

-- 创建猎人
function Level:CreateHunterEntity(bx, by, bz)
    local hunter = CreateHunterEntity(bx, by, bz);
    table.insert(self.__all_entity__, hunter);
    return hunter;
end

-- 创建狼
function Level:CreateWolfEntity(bx, by, bz)
    local wolf = CreateWolfEntity(bx, by, bz);
    wolf:SetDestroyCallBack(function()
        self:SetTaskItemCount(GoodsConfig.KILL_ENEMY.ID, self:GetTaskItemCount(GoodsConfig.KILL_ENEMY.ID) + 1);
    end);
    table.insert(self.__all_entity__, wolf);
    return wolf;
end

-- 创建箭塔
function Level:CreateTowerEntity(bx, by, bz)
    local towerbase = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "towerbase",
        assetfile = "@/blocktemplates/jiguannu_dipan.x",  
        hasBlood = false,
        isCanBeCollided = false,
    });
    towerbase:SetAnimId(5);
    local tower = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "tower",
        hasBlood = false,
        isCanBeCollided = false,
        assetfile = "@/blocktemplates/jiguannu.x",  
        defaultSkill = CreateSkill({
            entity_config = {
                name = "arrow",
                assetfile = "character/CC/07items/arrow.x", 
                speed = 5, 
                hasBlood = false,
                checkTerrain = false,
                isCanVisible = false,
                destroyBeCollided = true,
                biped = true,
                goods = {
                    [1] = {
                        gsid = GoodsConfig.ARROW.ID,
                        blood_peer = true,
                        blood_peer_value = -20, 
                    }
                }
            },
            skillDistance = 15,
            skillTime = 0,
            offsetY = 1,
            skillInterval = 400,
        })
    });

    table.insert(self.__all_entity__, towerbase);
    table.insert(self.__all_entity__, tower);

    __run__(function()
        while(self:GetLevelState() == 0 and __is_running__()) do
            tower:Turn(45);
            tower:Attack();
            sleep(500);
        end
    end);
    return tower;
end

function Level:CreateTorchEntity(bx, by, bz)
    local torch = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "towerbase",
        assetfile = "character/CC/artwar/game/huoba_ming.x",  
        destroyBeCollided = true,
        light = true,
        -- scale = 1.5,
    });
    torch:SetCollidedCallBack(function(self_entity, target_entity)
        target_entity:SetCanLight(true);
    end);
    table.insert(self.__all_entity__, torch);
    return torch;
end 

function Level:CreateTrapEntity(bx, by, bz)
    local trap = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "trap",
        assetfile = "@/blocktemplates/bushoujia.x",  
        destroyBeCollided = true,
        goods = {{dead_peer = true, name = "trap"}},
    });
    table.insert(self.__all_entity__, trap);
    return trap;
end

function Level:CreateCunMingEntity(bx, by, bz)
    local cunming = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "cunming",
        assetfile = "character/CC/02human/blockman/cunming.x",  
    });
    table.insert(self.__all_entity__, cunming);
    return cunming;
end

function Level:CreateCrossFenceEntity(bx, by, bz)
    local fence = CreateCrossFenceEntity(bx, by, bz);
    table.insert(self.__all_entity__, fence);
    return fence;
end

function Level:CreateLiangShiEntity(bx, by, bz)
    local liangshi = CreateLiangShiEntity(bx, by, bz);
    table.insert(self.__all_entity__, liangshi);
    return liangshi;
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