--[[
Title: Const
Author(s): wxa
Date: 2020/6/30
Desc: Const
use the lib:
-------------------------------------------------------
local Const = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Const.lua");
-------------------------------------------------------
]]

local Const = NPL.export();

Const.UnitSize = 4;                               -- 单元格大小
Const.DefaultUnitSize = 4;                        -- 默认单元格大小
Const.ConnectionRegionHeightUnitCount = 4;        -- 连接区域高度
Const.ConnectionRegionWidthUnitCount = 16;        -- 连接区域宽度
Const.ConnectionHeightUnitCount = 2;              -- 连接高度
Const.ConnectionWidthUnitCount = 16;              -- 连接高度
Const.BlockEdgeHeightUnitCount = 1;               -- 块边缘高度
Const.BlockEdgeWidthUnitCount = 1;                -- 块边缘高度

Const.LineHeightUnitCount = 6;                    -- 每行内容高为8
Const.InputValueWidthUnitCount = 10;              -- 输入值宽度
Const.FieldSpaceWidthUnitCount = 2;               -- 空白字段宽度

Const.MinEditFieldWidthUnitCount = 30;            -- 最小编辑字段宽度
Const.MaxTextShowWidthUnitCount = 100;            -- 最大文本显示宽度
Const.MinTextShowWidthUnitCount = 6;              -- 最小文本显示宽度
Const.TextMarginUnitCount = 1;                    -- 文本边距

Const.ToolBoxWidth = 300;                -- 工具栏宽度
Const.ToolBoxCategoryWidth = 80;         -- 分类宽
Const.ToolBoxCategoryHeight = 80;        -- 分类高