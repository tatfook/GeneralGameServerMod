--[[
Title: Vue
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Vue = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Vue.lua");
-------------------------------------------------------
]]

NPL.export({
    {
        type = "Vue:RegisterComponent",
        message0 = "注册元素 标签名 %1 文件路劲 %2",
        arg0 = {
            {
                name = "tagname",
                type = "field_input",
            },
            {
                name = "filename",
                type = "field_input"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local tagname = block:GetValueAsString("tagname");
            local filename = block:GetValueAsString("filename");
            return string.format('RegisterComponent(%s, %s)\n', tagname, filename);
        end,
    },
});