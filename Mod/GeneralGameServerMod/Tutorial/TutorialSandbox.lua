--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导API 
-----------------------------------------------
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local BlockStrategy = NPL.load("./BlockStrategy.lua", IsDevEnv);
local TutorialContext = NPL.load("./TutorialContext.lua", IsDevEnv);
local Page = NPL.load("./Page/Page.lua", IsDevEnv);

local TutorialSandbox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

TutorialSandbox:Property("Context");                                     -- 新手上下文环境
TutorialSandbox:Property("LastContext");                                 -- 上次上下文环境
TutorialSandbox:Property("LeftClickToDestroyBlockStrategy", {});         -- 配置左击删除方块策略
TutorialSandbox:Property("RightClickToCreateBlockStrategy", {});         -- 配置右击创建方块策略
TutorialSandbox:Property("Step", 0);                                     -- 第几步

function TutorialSandbox:ctor()
    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
end

function TutorialSandbox:Reset()
    self:SetContext(TutorialContext:new():Init(self));
    self:SetLastContext(SceneContextManager:GetCurrentContext());
    self:SetLeftClickToDestroyBlockStrategy({});
    self:SetRightClickToCreateBlockStrategy({});
    self:SetStep(0);
    self.stepTasks = {};                   -- 每步任务
    self.loadItems = {};                   -- 代码方块加载表
    self.allLoadFinishCallback = nil;      -- 全部加载完成回调

    GameLogic.GetCodeGlobal():GetCurrentGlobals()["TutorialSandbox"] = self;

    GameLogic.options.CanJumpInWater = true;
    GameLogic.options.CanJump = true;
    GameLogic.options.CanJumpInAir = true;
end

function TutorialSandbox:OnWorldLoaded()
    self:Reset();
end

function TutorialSandbox:OnWorldUnloaded()
end

function TutorialSandbox:SetCanFly(bFly)
    self:GetContext():SetCanFly(bFly);
end

function TutorialSandbox:SetCanJump(bJump)
    self:GetContext():SetCanJump(bJump);
end

function TutorialSandbox:SetLoadItems(loadItems, callback)
    for _, item in ipairs(loadItems) do
        self.loadItems[item] = false;
    end
    self.allLoadFinishCallback = callback;
end

function TutorialSandbox:FinishLoadItem(item)
    self.loadItems[item] = true;
    for item, loaded in pairs(self.loadItems) do
        if (not loaded) then return false end
    end

    if (type(self.allLoadFinishCallback) == "function") then
        self.allLoadFinishCallback();
    end

    return true;
end

-- 下一步
function TutorialSandbox:NextStep(isExecStepTask, ...)
    self:SetStep(self:GetStep() + 1);
    if (isExecStepTask) then
        local task = self.stepTasks[self:GetStep()];
        if (type(task) == "function") then
            return task(...);     
        end
    end
end

-- 设置步任务
function TutorialSandbox:SetStepTask(step, task)
    self.stepTasks[step] = task;
end

-- 获取Page
function TutorialSandbox:GetPage()
    return Page;
end

-- 获取玩家
function TutorialSandbox:GetPlayer()
    return EntityManager.GetPlayer();
end

-- 获取玩家库存
function TutorialSandbox:GetPlayerInventory()
    return self:GetPlayer().inventory;
end

-- 添加清除策略
function TutorialSandbox:AddLeftClickToDestroyBlockStrategy(strategy)
    strategy = BlockStrategy:new():Init(strategy);
    self:GetLeftClickToDestroyBlockStrategy()[strategy] = strategy;
    return strategy;
end

-- 移除清除策略
function TutorialSandbox:RemoveLeftClickToDestroyBlockStrategy(strategy)
    self:GetLeftClickToDestroyBlockStrategy()[strategy] = nil;
end

-- 添加创建策略
function TutorialSandbox:AddRightClickToCreateBlockStrategy(strategy)
    strategy = BlockStrategy:new():Init(strategy);
    self:GetRightClickToCreateBlockStrategy()[strategy] = strategy;
    return strategy;
end

-- 移除创建策略
function TutorialSandbox:RemoveRightClickToCreateBlockStrategy(strategy)
    self:GetRightClickToCreateBlockStrategy()[strategy] = nil;
end

-- 激活教学上下文
function TutorialSandbox:ActiveTutorialContext()
    local context = SceneContextManager:GetCurrentContext();
    if (not context:isa(TutorialContext)) then self:SetLastContext(context) end
    self:GetContext():activate();
end

-- 激活旧上下文
function TutorialSandbox:DeactiveTutorialContext()
    if (self:GetLastContext()) then 
        self:GetLastContext():activate();
    end
end

-- 左击是否可以删除
function TutorialSandbox:IsCanLeftClickToDestroyBlock(data)
    local strategy = self:GetLeftClickToDestroyBlockStrategy();
    if (type(strategy) ~= "table") then return end
    for _, item in pairs(strategy) do 
        if (item:IsMatch(data)) then return true end
    end

    return false;
end

-- 右击是否可以创建
function TutorialSandbox:IsCanRightClickToCreateBlock(data)
    local strategy = self:GetRightClickToCreateBlockStrategy();
    if (type(strategy) ~= "table") then return end
    for _, item in pairs(strategy) do 
        if (item:IsMatch(data)) then return true end
    end

    return false;
end

-- 初始化成单列模式
TutorialSandbox:InitSingleton();