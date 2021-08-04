--[[
Title: NplBlock
Author(s): wxa
Date: 2021/3/1
Desc: Lua
use the lib:
-------------------------------------------------------
local NplBlockDemo = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Blocks/NplBlockDemo.lua");
-------------------------------------------------------
]]

local MyLanguage = NPL.export();
local categories = {
	{name = "Hello", text = "Hello", colour = "#0078d7", },
	{name = "Control", text = "Control", colour = "#d83b01", },
};
local all_cmds = {
-----------------------
{
	type = "Hello", 
	message0 = "Hello %1",
	arg0 = {
		{
			name = "text",
			type = "input_value",
			shadow = { type = "text", value = L"hello!",},
			text = L"hello!", 
		},
	},
	category = "Hello", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'Hello(%s)',
	ToNPL = function(self)
		return string.format('Hello("%s")\n', self:getFieldValue('text'));
	end,
	examples = {{desc = "say hello ", canRun = true, code = [[
say("Hello!")
wait(1)
say("")
]]}},
},
-----------------------
{
	type = "Hello2", 
	message0 = "Hello2 %1",
	arg0 = {
		{
			name = "text",
			type = "input_value",
			shadow = { type = "text", value = L"hello!",},
			text = L"hello!", 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'say(%s)',
	ToNPL = function(self)
		return string.format('say("%s")\n', self:getFieldValue('text'));
	end,
	examples = {{desc = "say hello ", canRun = true, code = [[
say("Hello!")
wait(1)
say("")
]]}},
},

};

function MyLanguage.GetCategoryButtons()
	return categories;
end
function MyLanguage.GetAllCmds()
	return all_cmds;
end