
--[[
Title: ScrollBar
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local ScrollBar = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/ScrollBar.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua", IsDevEnv);
local ScrollBar = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ScrollBar:Property("Blockly");
ScrollBar:Property("Direction");  -- 方向        -- horizontal  vertical 

function ScrollBar:ctor()
end

function ScrollBar:Init(blockly, direction)
    self:SetBlockly(blockly);
    self:SetDirection(direction);
    
    return self;
end

function ScrollBar:IsHorizontal()
    return self:GetDirection() == "horizontal";
end

function ScrollBar:Render(painter)
    local blockly = self:GetBlockly();
    local isHideToolBox = blockly.isHideToolBox;
    local toolboxWidth = isHideToolBox and 0 or Const.ToolBoxWidth;
    local width, height = blockly:GetSize();
    local UnitSize = blockly:GetUnitSize();
    width = width - toolboxWidth;
    local __content_left_unit_count__, __content_top_unit_count__, __content_right_unit_count__, __content_bottom_unit_count__ = blockly.__content_left_unit_count__, blockly.__content_top_unit_count__, blockly.__content_right_unit_count__, blockly.__content_bottom_unit_count__;
    local __offset_x_unit_count__, __offset_y_unit_count__ = blockly.__offset_x_unit_count__, blockly.__offset_y_unit_count__;
    if (__content_left_unit_count__ == 0 and __content_top_unit_count__ == 0 and __content_bottom_unit_count__ == 0 and __content_right_unit_count__ == 0) then return end 
    local __content_width_unit_count__ = __content_right_unit_count__ - __content_left_unit_count__;
    local __content_height_unit_count__ = __content_bottom_unit_count__ - __content_top_unit_count__;
    local __content_offset_x_unit_count__ = __offset_x_unit_count__ - __content_left_unit_count__;
    local __content_offset_y_unit_count__ = __offset_y_unit_count__ - __content_top_unit_count__;
    -- print(1, __content_left_unit_count__, __content_top_unit_count__, __content_right_unit_count__, __content_bottom_unit_count__);
    -- print(2, __offset_x_unit_count__, __offset_y_unit_count__);
    -- print(3, __content_offset_x_unit_count__, __content_offset_y_unit_count__, __content_width_unit_count__, __content_height_unit_count__);
    if (self:IsHorizontal()) then
        self.__width__, self.__height__ = math.floor(width * width / (__content_width_unit_count__ * UnitSize)), UnitSize;
        self.__offset_x__, self.__offset_y__ = math.floor(width * __content_offset_x_unit_count__ / __content_width_unit_count__), height - UnitSize;
        -- print(4, self.__offset_x__, self.__offset_y__, self.__width__, self.__height__)
    else
        self.__width__, self.__height__ = UnitSize, math.floor(height * height / (__content_height_unit_count__ * UnitSize));
        self.__offset_x__, self.__offset_y__ = width - UnitSize, math.floor(height * __content_offset_y_unit_count__ / __content_height_unit_count__);
        -- print(5, self.__offset_x__, self.__offset_y__, self.__width__, self.__height__)
    end
    painter:SetPen("#00000080");
    painter:DrawRect(toolboxWidth + self.__offset_x__, self.__offset_y__, self.__width__, self.__height__);
    -- print(6, width, height, toolboxWidth);
end