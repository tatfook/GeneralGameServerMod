--[[
Title: UIBlock
Author(s): wxa
Date: 2021/3/1
Desc: Lua
use the lib:
-------------------------------------------------------
local UIBlock = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Blocks/UIBlock.lua");
-------------------------------------------------------
]]


local UIBlock = NPL.export();


local UI_Style_Item = {};
local Style_Key_Options = {
    {"宽", "width"}, 
    {"高", "height"}, 
    {"显示方式", "display"},
    {"弹性布局方向", "flex-direction"},
    {"主轴排列方式", "justify-content"},
    {"辅助排列方式", "align-items"},
    {"字体大小", "font-size"},
}
local Style_Value_Options = {
    ["display"] = { "flex", "block", "inline-block", "inline"},
    ["flex-direction"] = { "row", "column"},
    ["justify-content"] = {"center", "space-between", "space-around","flex-start", "flex-end"},
    ["align-items"] = {"center", "space-between", "space-around","flex-start", "flex-end"},
    ["font-size"] = {"10px", "12px", "14px", "16px", "18px", "20px", "24px", "28px", "30px", "36px", "40px", "50px"},
}

local function Style_Value_Options_Func(field)
    local block = field:GetBlock();
    local defaultOptions = {};
    if (not block) then return defaultOptions end
    local key = block:GetFieldValue("key") or "";
    return Style_Value_Options[key] or defaultOptions;
end

function UI_Style_Item.OnInit(option)
    local arg = option.arg;
    if (type(arg) ~= "table") then return end
    for _, field in ipairs(arg) do
        if (field.name == "key") then
            field.options = Style_Key_Options;
            field.isAllowCreate = true;
        end
        if (field.name == "value") then
            field.options = Style_Value_Options_Func;
            field.isAllowCreate = true;
        end
    end
end

UIBlock.UI_Style_Item = UI_Style_Item;