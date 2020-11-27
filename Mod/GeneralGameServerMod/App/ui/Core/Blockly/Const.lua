--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Const = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Const.lua");
-------------------------------------------------------
]]


local Const = NPL.export();

Const.UnitSize = 4;                               -- 单元格大小
Const.ConnectionRegionHeightUnitCount = 4;        -- 连接区域高度
Const.ConnectionRegionWidthUnitCount = 16;        -- 连接区域宽度
Const.ConnectionHeightUnitCount = 2;  -- 连接高度
Const.BlockEdgeHeightUnitCount = 1;   -- 块边缘高度
Const.BlockEdgeWidthUnitCount = 1;    -- 块边缘高度

Const.LineHeightUnitCount = 8;                    -- 每行内容高为8
Const.InputValueWidthUnitCount = 10;              -- 输入值宽度
Const.FieldSpaceWidthUnitCount = 2;               -- 空白字段宽度