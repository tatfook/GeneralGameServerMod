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
        type = "boolean",
        message0 = "%1",
        arg0 = {
            {
                name = "field_dropdown",
                type = "field_dropdown",
                text = "true",
                options = {
                    {"真", "true"},
                    {"假", "false"},
                }
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return block:GetFieldAsString("field_dropdown");
        end,
    },
    {
        type = "number",
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
        ToNPL = function(block) 
	    	return string.format('%s', block:GetFieldAsString("field_number"));
        end,
    },
    {
        type = "text",
        message0 = "\" %1 \"",
        arg0 = {
            {
                name = "field_input",
                type = "field_input",
                text = "文本",
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return string.format("\"%s\"", block:GetFieldAsString("field_input"));
        end,
    },
    {
        type = "variable",
        message0 = "%1",
        arg0 = {
            {
                name = "field_variable",
                type = "field_variable",
                allowNewOption = true,
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return block:GetFieldAsString("field_variable");
        end,
    },
    {
        type = "if",
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
        ToNPL = function(block)
            return string.format('if(%s) then\n    %s\nend\n', block:GetFieldAsString('input_value'), block:GetFieldAsString('input_statement'));
        end,
    },
    {
        type = "if_else",
        message0 = "如果 %1 那么 %2 否则 %3",
        arg0 = {
            {
                name = "expression",
                type = "input_value",
            },
            {
                name = "input_true",
                type = "input_statement"
            },
            {
                name = "input_else",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            return string.format('if(%s) then\n    %s\nelse\n    %s\nend\n', block:GetFieldAsString('expression'), block:GetFieldAsString('input_true'), block:GetFieldAsString('input_else'));
        end,
    },
    {
        type = "for",
        message0 = "每个 %1 , %2 在 %3 %4",
        arg0 = {
            {
                name = "key",
                type = "input_value",
            },
            {
                name = "value",
                type = "input_value",
            },
            {
                name = "data",
                type = "input_value",
            },
            {
                name = "input",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            return string.format('for %s, %s in pairs(%s) do\n    %s\nend\n', block:GetFieldAsString('key'), block:GetFieldAsString('value'), block:GetFieldAsString('data'), block:GetFieldAsString('input'));
        end,
    },
    {
        type = "for",
        message0 = "每个 %1 , %2 在数组 %3 %4",
        arg0 = {
            {
                name = "i",
                type = "input_value",
            },
            {
                name = "item",
                type = "input_value",
            },
            {
                name = "data",
                type = "input_value",
            },
            {
                name = "input",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            return string.format('for %s, %s in ipairs(%s) do\n    %s\nend\n', block:GetFieldAsString('i'), block:GetFieldAsString('item'), block:GetFieldAsString('data'), block:GetFieldAsString('input'));
        end,
    },
});