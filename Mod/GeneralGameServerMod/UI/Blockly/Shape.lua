--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Shape = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Shape.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua");
local Shape = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local Triangle = {{0,0,0}, {0,0,0}, {0,0,0}};       -- 三角形

Shape:Property("Pen", "#ffffff");              -- 画笔
Shape:Property("Brush", "#ffffff");            -- 画刷
Shape:Property("Painter");                     -- 绘图类
Shape:Property("DrawBorder", false, "IsDrawBorder");  -- 是否绘制边框
Shape:Property("UnitSize", 4);
-- 绘制上边缘
function Shape:DrawUpEdge(painter, widthUnitCount, fillHeightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());

    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    -- 绘制图形
    fillHeightUnitCount = fillHeightUnitCount or 0;
    painter:DrawRect(UnitSize, 0, (widthUnitCount - 2) * UnitSize, UnitSize);
    painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi / 2, math.pi);
    painter:DrawCircle(UnitSize * (widthUnitCount - 1), -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:DrawRect(0, UnitSize, widthUnitCount * UnitSize, UnitSize * (Const.BlockEdgeHeightUnitCount - 1));
    painter:DrawRect(0, Const.BlockEdgeHeightUnitCount * UnitSize, widthUnitCount * UnitSize, UnitSize * fillHeightUnitCount);
    painter:Flush();
    
    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        painter:DrawCircle(UnitSize, UnitSize, 0, UnitSize, "z", false, nil, math.pi, math.pi * 3 / 2);
        painter:DrawLine(UnitSize, 0, (widthUnitCount - 1) * UnitSize, 0);
        painter:DrawCircle(UnitSize * (widthUnitCount - 1), UnitSize, 0, UnitSize, "z", false, nil, math.pi * 3 / 2, math.pi * 2);
        painter:Flush();
    end
    
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制下边缘
function Shape:DrawDownEdge(painter, widthUnitCount, fillHeightUnitCount, offsetXUnitCount, offsetYUnitCount, isBlockInnerConnection)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());
    
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);
    -- 绘制图形
    fillHeightUnitCount = fillHeightUnitCount or 0;
    painter:DrawRect(0, 0, widthUnitCount * UnitSize, UnitSize * fillHeightUnitCount);
    painter:Translate(0, fillHeightUnitCount * UnitSize);
    painter:DrawRect(0, 0, widthUnitCount * UnitSize, UnitSize * (Const.BlockEdgeHeightUnitCount - 1));
    local OffsetY = Const.BlockEdgeHeightUnitCount - 1;
    if (isBlockInnerConnection) then
        painter:DrawRect(0, OffsetY * UnitSize, (widthUnitCount - 1) * UnitSize, UnitSize);
    else
        painter:DrawCircle(UnitSize, -OffsetY * UnitSize, 0, UnitSize, "z", true, nil, math.pi, math.pi * 3 / 2);
        painter:DrawRect(UnitSize, OffsetY * UnitSize, (widthUnitCount - 2) * UnitSize, UnitSize);
    end
    painter:DrawCircle(UnitSize * (widthUnitCount - 1), -OffsetY * UnitSize, 0, UnitSize, "z", true, nil, math.pi * 3 / 2, math.pi * 2);
    painter:Flush();
    
    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        if (isBlockInnerConnection) then
            painter:DrawLine(0, Const.BlockEdgeHeightUnitCount * UnitSize, (widthUnitCount - 1) * UnitSize, Const.BlockEdgeHeightUnitCount * UnitSize);
        else
            painter:DrawLine(0, -fillHeightUnitCount * UnitSize, 0, 0);
            painter:DrawCircle(UnitSize , 0, 0, UnitSize, "z", false, nil, math.pi / 2, math.pi);
            painter:DrawLine(UnitSize, Const.BlockEdgeHeightUnitCount * UnitSize, (widthUnitCount - 1) * UnitSize, Const.BlockEdgeHeightUnitCount * UnitSize);
        end
        painter:DrawLine(widthUnitCount * UnitSize, -fillHeightUnitCount * UnitSize, widthUnitCount * UnitSize, 0);
        painter:DrawCircle(UnitSize * (widthUnitCount - 1), 0, 0, UnitSize, "z", false, nil, 0, math.pi / 2);
        painter:Flush();
    end
    
    painter:Translate(0, -fillHeightUnitCount * UnitSize);
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制左边缘
function Shape:DrawLeftEdge(painter, heightUnitCount, fillWidthUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());
    
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    -- 绘制图形
    fillWidthUnitCount = fillWidthUnitCount or 0;
    painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi / 2, math.pi);
    painter:DrawRect(0, UnitSize, UnitSize, (heightUnitCount - 2) * UnitSize);
    painter:DrawCircle(UnitSize, -(heightUnitCount - 1) * UnitSize, 0, UnitSize, "z", true, nil, math.pi, math.pi * 3 / 2);
    painter:DrawRect(UnitSize, 0, (Const.BlockEdgeWidthUnitCount - 1) * UnitSize, heightUnitCount * UnitSize);
    painter:DrawRect(Const.BlockEdgeWidthUnitCount * UnitSize, 0, fillWidthUnitCount * UnitSize, heightUnitCount * UnitSize);
    painter:Flush();

    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        painter:DrawCircle(UnitSize, (heightUnitCount - 1) * UnitSize, 0, UnitSize, "z", false, nil, math.pi / 2, math.pi);
        painter:DrawLine(0, UnitSize, 0, (heightUnitCount - 1) * UnitSize);
        painter:DrawCircle(UnitSize,  UnitSize, 0, UnitSize, "z", false, nil, math.pi, math.pi * 3 / 2);
        painter:Flush();
    end
    
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制右边缘
function Shape:DrawRightEdge(painter, heightUnitCount, fillWidthUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());
    
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    -- 绘制图形
    fillWidthUnitCount = fillWidthUnitCount or 0;
    painter:DrawRect(0, 0, fillWidthUnitCount * UnitSize, heightUnitCount * UnitSize);
    painter:Translate(fillWidthUnitCount * UnitSize, 0);
    painter:DrawRect(0, 0, (Const.BlockEdgeWidthUnitCount - 1) * UnitSize, heightUnitCount * UnitSize);
    local OffsetX = Const.BlockEdgeWidthUnitCount - 1;
    painter:DrawCircle(OffsetX * UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:DrawRect(OffsetX * UnitSize, UnitSize, UnitSize, (heightUnitCount - 2) * UnitSize);
    painter:DrawCircle(OffsetX * UnitSize, -(heightUnitCount - 1) * UnitSize, 0, UnitSize, "z", true, nil, math.pi * 3 / 2, math.pi * 2);
    painter:Flush();

    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        painter:DrawCircle(0, (heightUnitCount - 1) * UnitSize, 0, UnitSize, "z", false, nil, 0, math.pi / 2);
        painter:DrawLine(Const.BlockEdgeWidthUnitCount * UnitSize, UnitSize, Const.BlockEdgeWidthUnitCount * UnitSize, (heightUnitCount - 1) * UnitSize);
        painter:DrawCircle(0 * UnitSize,  UnitSize, 0, UnitSize, "z", false, nil, math.pi * 3 / 2, math.pi * 2);
        painter:Flush();
    end
    
    painter:Translate(-fillWidthUnitCount * UnitSize, 0);
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制上边及凹陷部分 占据高度 2 * UnitSize
function Shape:DrawPrevConnection(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount, isBlockInnerConnection)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);
    local ConnectionSize = Const.ConnectionHeightUnitCount;
    
    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, Const.ConnectionHeightUnitCount * UnitSize, self:GetPrevConnectionTexture());

    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制下边及突出部分 占据高度 4 * UnitSize
function Shape:DrawNextConnection(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, (Const.ConnectionHeightUnitCount + 2) * UnitSize, self:GetNextConnectionTexture());
    
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制输出块
function Shape:DrawOutput(painter, widthUnitCount, heightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, heightUnitCount * UnitSize, self:GetOutputTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制输入字段
function Shape:DrawInputField(painter, widthUnitCount, heightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, heightUnitCount * UnitSize, self:GetOutputTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制矩形
function Shape:DrawRect(painter, leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(leftUnitCount * UnitSize, topUnitCount * UnitSize, widthUnitCount * UnitSize, heightUnitCount * UnitSize, self:GetRectTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制线条
function Shape:DrawLine(painter, x1, y1, x2, y2)
    local UnitSize = self:GetUnitSize();
    local painter = painter or self:GetPainter();
    painter:SetPen(self:GetPen());
    painter:DrawLine(x1 * UnitSize, y1 * UnitSize, x2 * UnitSize, y2 * UnitSize);
end

function Shape:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);
end

function Shape:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

function Shape:GetPrevConnectionTexture()
    return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_72X56_32bits.png#0 0 72 8:56 8 8 8";
end

function Shape:GetRectTexture()
    return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_72X56_32bits.png#0 16 72 16:4 4 4 4";
end

function Shape:GetNextConnectionTexture()
    return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_72X56_32bits.png#0 40 72 16:56 4 12 12";
end

function Shape:GetOutputTexture()
    return "Texture/Aries/Creator/keepwork/ggs/blockly/output_block_34X32_32bits.png#0 0 34 32:16 4 16 4";
end
