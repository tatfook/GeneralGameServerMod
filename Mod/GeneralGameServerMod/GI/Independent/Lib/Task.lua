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

TaskItem:Property("GoodsID");             -- 物品ID
TaskItem:Property("Count", 0);         -- 数量
TaskItem:Property("GoalCount", 1);     -- 目标数量

function TaskItem:Init(gsid, goalcount)
    self:SetGoodsID(gsid);
    self:SetGoalCount(goalcount);
    return self;
end

function Task:ctor()
    self.__task_item_list__ = {};
    self.__extra_task_item_list__ = {};
    self.__all_task_item__ = {};
end

function Task:AddTaskItem(gsid, goalcount)
    self.__all_task_item__[gsid] = TaskItem:new():Init(gsid, goalcount);
    table.insert(self.__task_item_list__, self.__all_task_item__[gsid]);
    print(self.__all_task_item__[gsid], self.__task_item_list__[#self.__task_item_list__])
end

function Task:AddExtraTaskItem(gsid, goalcount)
    self.__all_task_item__[gsid] = TaskItem:new():Init(gsid, goalcount);
    table.insert(self.__extra_task_item_list__, self.__all_task_item__[gsid]);
end

function Task:SetTaskItemCount(gsid, count)
    local taskitem = self.__all_task_item__[gsid];
    if (not taskitem) then return end 
    taskitem:SetCount(count or 0);
end

function Task:IsFinishGoal()
    for _, taskitem in ipairs(self.__task_item_list__) do
        if (taskitem:GetCount() < taskitem:GetGoalCount()) then
            return false;
        end
    end
    return true;
end

function Task:IsFinishExtraGoal()
    for _, taskitem in ipairs(self.__extra_task_item_list__) do
        if (taskitem:GetCount() < taskitem:GetGoalCount()) then
            return false;
        end
    end
    return true;
end

function Task:Clear()
    self.__all_task_item__ = {};
    self.__task_item_list__ = {};
    self.__extra_task_item_list__ = {};
end
