--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local GoodsConfig = require("%gi%/App/sunzibingfa/Level/GoodsConfig.lua");
local Task = require("Task");
local Level = inherit(require("Level"), module()) ;

Level.GoodsConfig = GoodsConfig;
Level:Property("PassLevelState", 0);        -- 0 初始态 1 通关 2 失败

function Level:ctor()
    self.__all_entity__ = {};
    self.__all_timer__ = {};
    self.__task__ = Task:new();
    self:SetPassLevelState(0);
end

function Level:AddPassLevelTask(gsid, count, title, description)
    local goods = GoodsConfig[gsid];
    self.__task__:AddTaskItem(gsid, count, goods and goods.task_title, goods and goods.task_description, goods and goods.task_reverse_compare);
end

function Level:AddPassLevelExtraTask(gsid, count, title, description)
    local goods = GoodsConfig[gsid];
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
    self.__task__:SetTaskItemCount(GoodsConfig.CODE_LINE.ID, self:GetStatementBlockCount());
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
    self.__all_entity__["pangjuan"] = pangjuan;
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
    self.__all_entity__["goalpoint"] = goalpoint;
    goalpoint:AddGoods(CreateGoods({gsid = GoodsConfig.GOAL_POINT.ID, title = "目标位置", description = "角色到达指定地点获得该物品", transfer = true}));
    return goalpoint;
end

-- 创建猎人
function Level:CreateHunterEntity(bx, by, bz)
    local hunter = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "hunter",
        biped = true,
        assetfile = "character/CC/artwar/game/lieren.x",  
        isAutoAttack = true,
        types = {["hunter"] = 0, ["wolf"] = 1},
        visibleRadius = 10,
        defaultSkill = CreateSkill({
            skillRadius = 10,
            entity_config = {assetfile = "character/CC/07items/arrow.x", speed = 5, checkTerrain = false},
            moveToTargetEntity = true,
            skillDistance = 15,
        }),
    });
    self.__all_entity__["hunter"] = hunter;
    return hunter;
end

-- 创建狼
function Level:CreateWolfEntity(bx, by, bz)
    local wolf = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "wolf",
        biped = true,
        assetfile = "character/CC/codewar/lang.x",  
        isAutoAttack = true,
        types = {["wolf"] = 0, ["human"] = 1},
        visibleRadius = 5,
        defaultSkill = CreateSkill({
            skillRadius = 1,
        }),
    });
    self.__all_entity__["wolf"] = wolf;
    return wolf;
end

-- 创建箭塔
function Level:CreateTowerEntity(bx, by, bz)
    local towerbase = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "towerbase",
        assetfile = "@/blocktemplates/jiguannu_dipan.x",  
        hasBloold = false,
        canBeCollided = false,
    });
    towerbase:SetAnimId(5);
    local tower = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "tower",
        hasBloold = false,
        canBeCollided = false,
        assetfile = "@/blocktemplates/jiguannu.x",  
        defaultSkill = CreateSkill({
            entity_config = {
                name = "arrow",
                assetfile = "character/CC/07items/arrow.x", 
                speed = 5, 
                hasBloold = false,
                checkTerrain = false,
                canVisible = false,
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

    self.__all_entity__["towerbase"] = towerbase;
    self.__all_entity__["tower"] = tower;

    __run__(function()
        while(self:GetPassLevelState() == 0 and __is_running__()) do
            tower:Turn(45);
            tower:Attack();
            sleep(500);
        end
    end);
    return tower;
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