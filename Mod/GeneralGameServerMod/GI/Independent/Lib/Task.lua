--[[
Title: Task
Author(s):  wxa
Date: 2021-06-01
Desc: 任务类 
use the lib:
------------------------------------------------------------
local Task = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Task.lua");
------------------------------------------------------------
]]

local Task = inherit(ToolBase, module("Task"));

local TaskItem = inherit(ToolBase, {});

local __task_page__ = nil;
local __scope__ = NewScope();

TaskItem:Property("Task");             -- 所属任务
TaskItem:Property("GoodsID");          -- 物品ID
TaskItem:Property("Title");            -- 标题
TaskItem:Property("Description");      -- 描述
TaskItem:Property("Count", 0);         -- 数量
TaskItem:Property("GoalCount", 1);     -- 目标数量
TaskItem:Property("ReverseCompare", false, "IsReverseCompare"); -- 是否反向比较
TaskItem:Property("FinishCallBack");   -- 完成回调

function TaskItem:Init(task, gsid, goalcount, title, description, reverse_compare)
    self:SetTask(task);
    self:SetGoodsID(gsid);
    self:SetGoalCount(goalcount);
    self:SetTitle(title);
    self:SetDescription(description);
    self:SetReverseCompare(reverse_compare);
    return self;
end

function TaskItem:IsFinish()
    local count = self:GetCount();
    local goalcount = self:GetGoalCount();
    return if_else(self:IsReverseCompare(), count <= goalcount, count >= goalcount);
end

function TaskItem:CheckFinish()
    if (not self:IsFinish()) then return end
    local callback = self:GetFinishCallBack();
    if (type(callback) == "function") then callback() end
end

function TaskItem:Stop()
end

function TaskItem:Destroy()
end


local TimeTaskItem = inherit(TaskItem, {});

function TimeTaskItem:Init(task, gsid, goalcount, title, description, reverse_compare)
    TimeTaskItem._super.Init(self, task, gsid, goalcount, title, description, reverse_compare);

    self.__timer__ = SetInterval(1000, function()
        self:SetCount(self:GetCount() + 1);
        self:GetTask():RefreshUI();
        self:CheckFinish();
    end);

    return self;
end

function TimeTaskItem:Stop()
    if (not self.__timer__) then return end
    self.__timer__:Stop();
    self.__timer__ = nil;
end

function TimeTaskItem:Destroy()
    if (not self.__timer__) then return end
    self.__timer__:Stop();
    self.__timer__ = nil;
end

function Task:ctor()
    self.__task_item_list__ = {};
    self.__extra_task_item_list__ = {};
    self.__all_task_item__ = {};
end

function Task:GetTaskItem(TaskItemClass, ...)
    TaskItemClass = TaskItemClass or TaskItem;
    return TaskItemClass:new():Init(self, ...);
end

function Task:__AddTaskItem__(TaskItemClass, ...)
    local taskitem = self:GetTaskItem(TaskItemClass, ...);
    self.__all_task_item__[taskitem:GetGoodsID()] = taskitem;
    table.insert(self.__task_item_list__, taskitem);
    self:RefreshUI();
    return taskitem;
end

function Task:__AddExtraTaskItem__(TaskItemClass, ...)
    local taskitem = self:GetTaskItem(TaskItemClass, ...);
    self.__all_task_item__[taskitem:GetGoodsID()] = taskitem;
    table.insert(self.__extra_task_item_list__, taskitem);
    self:RefreshUI();
    return taskitem;
end

function Task:AddTaskItem(gsid, goalcount, title, description, reverse_compare)
    return self:__AddTaskItem__(TaskItem, gsid, goalcount, title, description, reverse_compare);
end

function Task:AddExtraTaskItem(gsid, goalcount, title, description, reverse_compare)
    return self:__AddExtraTaskItem__(TaskItem, gsid, goalcount, title, description, reverse_compare);
end

function Task:AddTimeTaskItem(gsid, goalcount, title, description, reverse_compare)
    return self:__AddTaskItem__(TimeTaskItem, gsid, goalcount, title, description, reverse_compare);
end

function Task:AddTimeExtraTaskItem(gsid, goalcount, title, description, reverse_compare)
    return self:__AddExtraTaskItem__(TimeTaskItem, gsid, goalcount, title, description, reverse_compare);
end

function Task:GetTaskItemCount(gsid)
    local taskitem = self.__all_task_item__[gsid];
    return taskitem and taskitem:GetCount() or 0;
end

function Task:SetTaskItemCount(gsid, count)
    local taskitem = self.__all_task_item__[gsid];
    if (not taskitem) then return end 
    taskitem:SetCount(count or 0);
    
    self:RefreshUI();
end

function Task:IsFinishGoal()
    for _, taskitem in ipairs(self.__task_item_list__) do
        if (not taskitem:IsFinish()) then
            return false;
        end
    end
    return true;
end

function Task:IsFinishExtraGoal()
    for _, taskitem in ipairs(self.__extra_task_item_list__) do
        if (not taskitem:IsFinish()) then
            return false;
        end
    end
    return true;
end

function Task:Clear()
    for _, taskitem in pairs(self.__all_task_item__) do
        taskitem:Destroy();
    end
    
    self.__all_task_item__ = {};
    self.__task_item_list__ = {};
    self.__extra_task_item_list__ = {};
end

function Task:RefreshUI()
    local function GetTaskItemList(__task_item_list__)
        local taskitemlist = {};
        for _, item in ipairs(__task_item_list__) do
            table.insert(taskitemlist, {
                gsid = item:GetGoodsID();
                count = item:GetCount(),
                goalcount = item:GetGoalCount(),
                title = item:GetTitle(),
            });
        end
        return taskitemlist;
    end

    local state = "未完成";
    local IsFinishGoal = self:IsFinishGoal();
    local IsFinishExtraGoal = self:IsFinishExtraGoal();
    if (IsFinishGoal and IsFinishExtraGoal) then state = "全部完成" 
    elseif (IsFinishGoal) then state = "挑战成功"
    end

    __scope__:Set("state", state);
    __scope__:Set("taskitem_list", GetTaskItemList(self.__task_item_list__));
    __scope__:Set("extra_taskitem_list", GetTaskItemList(self.__extra_task_item_list__));
end

function Task:ShowUI(G, params)
    G = G or {};
    G.GlobalScope = __scope__;

    params = params or {};
    params.url = params.url or "%gi%/Independent/UI/Task.html";
    params.alignment = params.alignment or "_lt";
    params.width = params.width or 200;
    params.height = params.height or 240;
    params.x = params.x or 4;
    params.y = params.y or 4;
    params.minRootScreenWidth = params.minRootScreenWidth or 600;
    params.minRootScreenHeight = params.minRootScreenHeight or 600;

    self:RefreshUI();
    __task_page__ = ShowWindow(G, params);
    return __task_page__;
end

function Task:IsShowUI()
    return __task_page__ ~= nil;
end

function Task:CloseUI()
    if (not __task_page__) then return end
    __task_page__:CloseWindow();
    __task_page__ = nil;
end
