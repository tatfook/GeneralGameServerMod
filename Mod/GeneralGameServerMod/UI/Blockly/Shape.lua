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
    if (isBlockInnerConnection) then
        painter:DrawRect(0, 0, UnitSize * 4, UnitSize);
    else
        painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi / 2, math.pi);
        painter:DrawRect(UnitSize, 0, UnitSize * 3, UnitSize);
    end
    painter:DrawRect(0, UnitSize, UnitSize * 4, UnitSize * (ConnectionSize - 1));
    painter:Translate(UnitSize * 4, 0);

    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -UnitSize * ConnectionSize, UnitSize * ConnectionSize, -UnitSize * ConnectionSize;
    painter:DrawTriangleList(Triangle);
    
    painter:Translate(UnitSize * (4 + ConnectionSize), 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, -UnitSize * ConnectionSize, UnitSize * ConnectionSize, -UnitSize * ConnectionSize, UnitSize * ConnectionSize, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(UnitSize * ConnectionSize, 0);
    
    local remainSize = widthUnitCount - 9 - ConnectionSize * 2;
    painter:DrawRect(0, 0, UnitSize * remainSize, UnitSize);
    painter:DrawRect(0, UnitSize, UnitSize * (remainSize + 1), UnitSize * (ConnectionSize - 1));
    painter:Translate(UnitSize * remainSize, 0);
    painter:DrawCircle(0, -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:Translate(-(widthUnitCount - 1) * UnitSize, 0);
    painter:Flush();

    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        if (isBlockInnerConnection) then
            painter:DrawLine(0, 0, 4 * UnitSize, 0);
        else 
            painter:DrawLine(0, UnitSize, 0, UnitSize * ConnectionSize);
            painter:DrawCircle(UnitSize, UnitSize, 0, UnitSize, "z", false, nil, math.pi, math.pi * 3 / 2);
            painter:DrawLine(UnitSize, 0, 4 * UnitSize, 0);
        end
        painter:DrawLine(4 * UnitSize, 0, (4 + ConnectionSize) * UnitSize, ConnectionSize * UnitSize);
        painter:DrawLine((4 + ConnectionSize) * UnitSize, ConnectionSize * UnitSize, (8 + ConnectionSize) * UnitSize, ConnectionSize * UnitSize);
        painter:DrawLine((8 + ConnectionSize) * UnitSize, ConnectionSize * UnitSize, (8 + 2 * ConnectionSize) * UnitSize, 0);
        painter:DrawLine((8 + 2 * ConnectionSize) * UnitSize, 0, (widthUnitCount - 1) * UnitSize, 0);
        painter:DrawCircle(UnitSize * (widthUnitCount - 1), UnitSize, 0, UnitSize, "z", false, nil, math.pi * 3 / 2, math.pi * 2);
        painter:DrawLine(UnitSize * widthUnitCount, (ConnectionSize - 1) * UnitSize, UnitSize * widthUnitCount, UnitSize * ConnectionSize);
        painter:Flush();
    end

    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制下边及突出部分 占据高度 4 * UnitSize
function Shape:DrawNextConnection(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount, isBlockInnerConnection)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());
    
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    local ConnectionSize = Const.ConnectionHeightUnitCount;
    self:DrawDownEdge(painter, widthUnitCount, ConnectionSize - Const.BlockEdgeHeightUnitCount, nil, nil, isBlockInnerConnection);
    painter:Translate(0, ConnectionSize * UnitSize);
    
    painter:SetPen(self:GetBrush());
    -- 下边突出部分
    painter:Translate(4 * UnitSize, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, UnitSize * ConnectionSize, -UnitSize * ConnectionSize, UnitSize * ConnectionSize, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(ConnectionSize * UnitSize, 0);
    painter:DrawRect(0, 0, UnitSize * 4, UnitSize * ConnectionSize);
    painter:Translate(4 * UnitSize, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -UnitSize * ConnectionSize, UnitSize * ConnectionSize, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(-(8 + ConnectionSize) * UnitSize,  0);
    painter:Flush();

    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetBrush());
        painter:DrawLine(4 * UnitSize, 0, 12 * UnitSize, 0);
        painter:SetPen(self:GetPen());
        painter:DrawLine(4 * UnitSize, 0, (4 + ConnectionSize) * UnitSize, ConnectionSize * UnitSize);
        painter:DrawLine((4 + ConnectionSize) * UnitSize, ConnectionSize * UnitSize, (8 + ConnectionSize) * UnitSize, ConnectionSize * UnitSize);
        painter:DrawLine((8 + ConnectionSize) * UnitSize, ConnectionSize * UnitSize, (8 + 2 * ConnectionSize) * UnitSize, 0);
        painter:Flush();
    end
    
    painter:Translate(0, -ConnectionSize * UnitSize);
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制矩形
function Shape:DrawRect(painter, leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    local painter = painter or self:GetPainter();
    painter:SetPen(self:GetBrush());
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);
    painter:DrawRect(leftUnitCount * UnitSize, topUnitCount * UnitSize, widthUnitCount * UnitSize, heightUnitCount * UnitSize);
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制线条
function Shape:DrawLine(painter, x1, y1, x2, y2)
    local UnitSize = self:GetUnitSize();
    local painter = painter or self:GetPainter();
    painter:SetPen(self:GetPen());
    painter:DrawLine(x1 * UnitSize, y1 * UnitSize, x2 * UnitSize, y2 * UnitSize);
end
