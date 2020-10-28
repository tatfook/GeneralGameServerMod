--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Block = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Block.lua");
-------------------------------------------------------
]]

local Input = NPL.load("./Input.lua", IsDevEnv);
local Connection = NPL.load("./Connection.lua", IsDevEnv);

local Block = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Block:Property("Output");                   -- 输出链接
Block:Property("PrevStatement");            -- 上一条语句
Block:Property("NextStatement");            -- 下一条语句

function Block:ctor()
    self.inputs = {};                       -- 块内输入
end


