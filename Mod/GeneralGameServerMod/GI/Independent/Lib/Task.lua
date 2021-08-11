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

TaskItem:Property("GoodsID");          -- 物品ID
TaskItem:Property("Title");            -- 标题
TaskItem:Property("Description");      -- 描述
TaskItem:Property("Count", 0);         -- 数量
TaskItem:Property("GoalCount", 1);     -- 目标数量
TaskItem:Property("ReverseCompare", false, "IsReverseCompare"); -- 是否反向比较

function TaskItem:Init(gsid, goalcount, title, description, reverse_compare)
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

function TaskItem:Destroy()
end

function Task:ctor()
    self.__task_item_list__ = {};
    self.__extra_task_item_list__ = {};
    self.__all_task_item__ = {};
end

function Task:AddTaskItem(gsid, goalcount, title, description, reverse_compare)
    local taskitem = TaskItem:new():Init(gsid, goalcount, title, description, reverse_compare);
    self.__all_task_item__[gsid] = taskitem;
    table.insert(self.__task_item_list__, taskitem);
    self:RefreshUI();
    return taskitem;
end

function Task:AddExtraTaskItem(gsid, goalcount, title, description, reverse_compare)
    local taskitem = TaskItem:new():Init(gsid, goalcount, title, description, reverse_compare);
    self.__all_task_item__[gsid] = taskitem;
    table.insert(self.__extra_task_item_list__, taskitem);
    self:RefreshUI();
    return taskitem;
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
