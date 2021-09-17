--[[
Title: VariableView
Author(s):  wxa
Date: 2021-06-01
Desc: Debug
use the lib:
------------------------------------------------------------
local VariableView = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/VariableView.lua");
------------------------------------------------------------
]]

local VariableView = inherit(ToolBase, module("VariableView"));

function VariableView:ctor()
    self.__vars__ = {};
    self.__var_stack__ = {};
    self.__ui__ = nil;
end

-- 添加观察键值对
function VariableView:AddWatchKeyValue(key, val)
    self.__vars__[key] = val;
    self:RefreshUI();
end

function VariableView:Clear()
    self.__vars__ = {};
    self.__var_stack__ = {};
    self:RefreshUI();
end

function VariableView:RefreshUI()
    if (self.__ui__) then self:ShowUI() end 
end

function VariableView:ShowUI()
    local x, y, width, height = 0, 0, 340, 320;
    if (self.__ui__) then x, y, width, height = self.__ui__:GetNativeWindow():GetAbsPosition() end
    
    self:CloseUI();
    
    local cur_vars = self.__vars__;
    for index, var in ipairs(self.__var_stack__) do
        if (cur_vars[var.key] ~= var.value) then
            for i = index, #(self.__var_stack__) do 
                self.__var_stack__[i] = nil;
            end
            break;
        else 
            cur_vars = var.value;
        end
    end

    self.__ui__ = ShowWindow({
        __vars__ = self.__vars__,
        __var_stack__ = self.__var_stack__,
    }, {
        url = "%gi%/Independent/UI/VariableView.html",
        alignment = "_lt",
        x = x, y = y, width = width, height = height,
        draggable = true,
    });
end

function VariableView:CloseUI()
    if (self.__ui__) then self.__ui__:CloseWindow() end 
    self.__ui__ = nil;
end

VariableView:InitSingleton();
