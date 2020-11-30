--[[
Title: Lua
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Lua = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Lua.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");


NPL.export({
    {
        name = "boolean",
        message0 = "%1",
        arg0 = {
            {
                name = "field_dropdown",
                type = "field_dropdown",
                text = "真",
                options = {
                    {"真", "true"},
                    {"假", "false"},
                }
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
    },
    {
        name = "number",
        message0 = "%1",
        arg0 = {
            {
                name = "field_number",
                type = "field_number",
                text = "0",
                min = 0,
                max = 100,
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
    },
    {
        name = "text",
        message0 = "%1",
        arg0 = {
            {
                name = "field_input",
                type = "field_input",
                text = "文本",
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
    },
    {
        name = "if",
        message0 = "如果 %1 那么",
        arg0 = {
            {
                name = "input_value",
                type = "input_value",
            },
        },
        message1 = "%1",
        arg1 = {
            {
                name = "input_statement",
                type = "input_statement"
            }
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
    },
    {
        name = "if_else",
        message0 = "如果 %1 那么 %2 否则 %3",
        arg0 = {
            {
                name = "input_value",
                type = "input_value",
            },
            {
                name = "input_statement",
                type = "input_statement"
            },
            {
                name = "input_statement",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
    },
    {
        name = "for",
        message0 = "每个 %1 , %2 在 %3 %4",
        arg0 = {
            {
                name = "input_value",
                type = "input_value",
            },
            {
                name = "input_value",
                type = "input_value",
            },
            {
                name = "input_value",
                type = "input_value",
            },
            {
                name = "input_statement",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
    },
});