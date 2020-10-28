--[[
Title: Connection
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Connection = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Connection.lua");
-------------------------------------------------------
]]

local Connection = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Connection:Property("Block");  -- 所属块
Connection:Property("Check");  -- 连接核对 是否可以链接
Connection:Property("Type");   -- 类型 statement  value

function Connection:ctor()
end

function Connection:Init(block)
    self:SetBlock(block);

    return self;
end
