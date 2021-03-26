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

-- 绘制上边缘
function Shape:DrawUpEdge(painter, widthUnitCount, fillHeightUnitCount, offsetXUnitCount, offsetYUnitCount)
    painter:SetPen(self:GetBrush());

    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * Const.UnitSize, offsetYUnitCount * Const.UnitSize);

    -- 绘制图形
    fillHeightUnitCount = fillHeightUnitCount or 0;
    painter:DrawRect(Const.UnitSize, 0, (widthUnitCount - 2) * Const.UnitSize, Const.UnitSize);
    painter:DrawCircle(Const.UnitSize, -Const.UnitSize, 0, Const.UnitSize, "z", true, nil, math.pi / 2, math.pi);
    painter:DrawCircle(Const.UnitSize * (widthUnitCount - 1), -Const.UnitSize, 0, Const.UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:DrawRect(0, Const.UnitSize, widthUnitCount * Const.UnitSize, Const.UnitSize * (Const.BlockEdgeHeightUnitCount - 1));
    painter:DrawRect(0, Const.BlockEdgeHeightUnitCount * Const.UnitSize, widthUnitCount * Const.UnitSize, Const.UnitSize * fillHeightUnitCount);
    painter:Flush();
    
    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        painter:DrawCircle(Const.UnitSize, Const.UnitSize, 0, Const.UnitSize, "z", false, nil, math.pi, math.pi * 3 / 2);
        painter:DrawLine(Const.UnitSize, 0, (widthUnitCount - 1) * Const.UnitSize, 0);
        painter:DrawCircle(Const.UnitSize * (widthUnitCount - 1), Const.UnitSize, 0, Const.UnitSize, "z", false, nil, math.pi * 3 / 2, math.pi * 2);
        painter:Flush();
    end
    
    painter:Translate(-offsetXUnitCount * Const.UnitSize, -offsetYUnitCount * Const.UnitSize);
end

-- 绘制下边缘
function Shape:DrawDownEdge(painter, widthUnitCount, fillHeightUnitCount, offsetXUnitCount, offsetYUnitCount, isBlockInnerConnection)
    painter:SetPen(self:GetBrush());
    
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * Const.UnitSize, offsetYUnitCount * Const.UnitSize);
    -- 绘制图形
    fillHeightUnitCount = fillHeightUnitCount or 0;
    painter:DrawRect(0, 0, widthUnitCount * Const.UnitSize, Const.UnitSize * fillHeightUnitCount);
    painter:Translate(0, fillHeightUnitCount * Const.UnitSize);
    painter:DrawRect(0, 0, widthUnitCount * Const.UnitSize, Const.UnitSize * (Const.BlockEdgeHeightUnitCount - 1));
    local OffsetY = Const.BlockEdgeHeightUnitCount - 1;
    if (isBlockInnerConnection) then
        painter:DrawRect(0, OffsetY * Const.UnitSize, (widthUnitCount - 1) * Const.UnitSize, Const.UnitSize);
    else
        painter:DrawCircle(Const.UnitSize, -OffsetY * Const.UnitSize, 0, Const.UnitSize, "z", true, nil, math.pi, math.pi * 3 / 2);
        painter:DrawRect(Const.UnitSize, OffsetY * Const.UnitSize, (widthUnitCount - 2) * Const.UnitSize, Const.UnitSize);
    end
    painter:DrawCircle(Const.UnitSize * (widthUnitCount - 1), -OffsetY * Const.UnitSize, 0, Const.UnitSize, "z", true, nil, math.pi * 3 / 2, math.pi * 2);
    painter:Flush();
    
    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        if (isBlockInnerConnection) then
            painter:DrawLine(0, Const.BlockEdgeHeightUnitCount * Const.UnitSize, (widthUnitCount - 1) * Const.UnitSize, Const.BlockEdgeHeightUnitCount * Const.UnitSize);
        else
            painter:DrawLine(0, -fillHeightUnitCount * Const.UnitSize, 0, 0);
            painter:DrawCircle(Const.UnitSize , 0, 0, Const.UnitSize, "z", false, nil, math.pi / 2, math.pi);
            painter:DrawLine(Const.UnitSize, Const.BlockEdgeHeightUnitCount * Const.UnitSize, (widthUnitCount - 1) * Const.UnitSize, Const.BlockEdgeHeightUnitCount * Const.UnitSize);
        end
        painter:DrawLine(widthUnitCount * Const.UnitSize, -fillHeightUnitCount * Const.UnitSize, widthUnitCount * Const.UnitSize, 0);
        painter:DrawCircle(Const.UnitSize * (widthUnitCount - 1), 0, 0, Const.UnitSize, "z", false, nil, 0, math.pi / 2);
        painter:Flush();
    end
    
    painter:Translate(0, -fillHeightUnitCount * Const.UnitSize);
    painter:Translate(-offsetXUnitCount * Const.UnitSize, -offsetYUnitCount * Const.UnitSize);
end

-- 绘制左边缘
function Shape:DrawLeftEdge(painter, heightUnitCount, fillWidthUnitCount, offsetXUnitCount, offsetYUnitCount)
    painter:SetPen(self:GetBrush());
    
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * Const.UnitSize, offsetYUnitCount * Const.UnitSize);

    -- 绘制图形
    fillWidthUnitCount = fillWidthUnitCount or 0;
    painter:DrawCircle(Const.UnitSize, -Const.UnitSize, 0, Const.UnitSize, "z", true, nil, math.pi / 2, math.pi);
    painter:DrawRect(0, Const.UnitSize, Const.UnitSize, (heightUnitCount - 2) * Const.UnitSize);
    painter:DrawCircle(Const.UnitSize, -(heightUnitCount - 1) * Const.UnitSize, 0, Const.UnitSize, "z", true, nil, math.pi, math.pi * 3 / 2);
    painter:DrawRect(Const.UnitSize, 0, (Const.BlockEdgeWidthUnitCount - 1) * Const.UnitSize, heightUnitCount * Const.UnitSize);
    painter:DrawRect(Const.BlockEdgeWidthUnitCount * Const.UnitSize, 0, fillWidthUnitCount * Const.UnitSize, heightUnitCount * Const.UnitSize);
    painter:Flush();

    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        painter:DrawCircle(Const.UnitSize, (heightUnitCount - 1) * Const.UnitSize, 0, Const.UnitSize, "z", false, nil, math.pi / 2, math.pi);
        painter:DrawLine(0, Const.UnitSize, 0, (heightUnitCount - 1) * Const.UnitSize);
        painter:DrawCircle(Const.UnitSize,  Const.UnitSize, 0, Const.UnitSize, "z", false, nil, math.pi, math.pi * 3 / 2);
        painter:Flush();
    end
    
    painter:Translate(-offsetXUnitCount * Const.UnitSize, -offsetYUnitCount * Const.UnitSize);
end

-- 绘制右边缘
function Shape:DrawRightEdge(painter, heightUnitCount, fillWidthUnitCount, offsetXUnitCount, offsetYUnitCount)
    painter:SetPen(self:GetBrush());
    
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * Const.UnitSize, offsetYUnitCount * Const.UnitSize);

    -- 绘制图形
    fillWidthUnitCount = fillWidthUnitCount or 0;
    painter:DrawRect(0, 0, fillWidthUnitCount * Const.UnitSize, heightUnitCount * Const.UnitSize);
    painter:Translate(fillWidthUnitCount * Const.UnitSize, 0);
    painter:DrawRect(0, 0, (Const.BlockEdgeWidthUnitCount - 1) * Const.UnitSize, heightUnitCount * Const.UnitSize);
    local OffsetX = Const.BlockEdgeWidthUnitCount - 1;
    painter:DrawCircle(OffsetX * Const.UnitSize, -Const.UnitSize, 0, Const.UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:DrawRect(OffsetX * Const.UnitSize, Const.UnitSize, Const.UnitSize, (heightUnitCount - 2) * Const.UnitSize);
    painter:DrawCircle(OffsetX * Const.UnitSize, -(heightUnitCount - 1) * Const.UnitSize, 0, Const.UnitSize, "z", true, nil, math.pi * 3 / 2, math.pi * 2);
    painter:Flush();

    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        painter:DrawCircle(0, (heightUnitCount - 1) * Const.UnitSize, 0, Const.UnitSize, "z", false, nil, 0, math.pi / 2);
        painter:DrawLine(Const.BlockEdgeWidthUnitCount * Const.UnitSize, Const.UnitSize, Const.BlockEdgeWidthUnitCount * Const.UnitSize, (heightUnitCount - 1) * Const.UnitSize);
        painter:DrawCircle(0 * Const.UnitSize,  Const.UnitSize, 0, Const.UnitSize, "z", false, nil, math.pi * 3 / 2, math.pi * 2);
        painter:Flush();
    end
    
    painter:Translate(-fillWidthUnitCount * Const.UnitSize, 0);
    painter:Translate(-offsetXUnitCount * Const.UnitSize, -offsetYUnitCount * Const.UnitSize);
end

-- 绘制上边及凹陷部分 占据高度 2 * Const.UnitSize
function Shape:DrawPrevConnection(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount, isBlockInnerConnection)
    painter:SetPen(self:GetBrush());
    
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * Const.UnitSize, offsetYUnitCount * Const.UnitSize);

    local ConnectionSize = Const.ConnectionHeightUnitCount;
    if (isBlockInnerConnection) then
        painter:DrawRect(0, 0, Const.UnitSize * 4, Const.UnitSize);
    else
        painter:DrawCircle(Const.UnitSize, -Const.UnitSize, 0, Const.UnitSize, "z", true, nil, math.pi / 2, math.pi);
        painter:DrawRect(Const.UnitSize, 0, Const.UnitSize * 3, Const.UnitSize);
    end
    painter:DrawRect(0, Const.UnitSize, Const.UnitSize * 4, Const.UnitSize * (ConnectionSize - 1));
    painter:Translate(Const.UnitSize * 4, 0);

    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -Const.UnitSize * ConnectionSize, Const.UnitSize * ConnectionSize, -Const.UnitSize * ConnectionSize;
    painter:DrawTriangleList(Triangle);
    
    painter:Translate(Const.UnitSize * (4 + ConnectionSize), 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, -Const.UnitSize * ConnectionSize, Const.UnitSize * ConnectionSize, -Const.UnitSize * ConnectionSize, Const.UnitSize * ConnectionSize, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(Const.UnitSize * ConnectionSize, 0);
    
    local remainSize = widthUnitCount - 9 - ConnectionSize * 2;
    painter:DrawRect(0, 0, Const.UnitSize * remainSize, Const.UnitSize);
    painter:DrawRect(0, Const.UnitSize, Const.UnitSize * (remainSize + 1), Const.UnitSize * (ConnectionSize - 1));
    painter:Translate(Const.UnitSize * remainSize, 0);
    painter:DrawCircle(0, -Const.UnitSize, 0, Const.UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:Translate(-(widthUnitCount - 1) * Const.UnitSize, 0);
    painter:Flush();

    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetPen());
        if (isBlockInnerConnection) then
            painter:DrawLine(0, 0, 4 * Const.UnitSize, 0);
        else 
            painter:DrawLine(0, Const.UnitSize, 0, Const.UnitSize * ConnectionSize);
            painter:DrawCircle(Const.UnitSize, Const.UnitSize, 0, Const.UnitSize, "z", false, nil, math.pi, math.pi * 3 / 2);
            painter:DrawLine(Const.UnitSize, 0, 4 * Const.UnitSize, 0);
        end
        painter:DrawLine(4 * Const.UnitSize, 0, (4 + ConnectionSize) * Const.UnitSize, ConnectionSize * Const.UnitSize);
        painter:DrawLine((4 + ConnectionSize) * Const.UnitSize, ConnectionSize * Const.UnitSize, (8 + ConnectionSize) * Const.UnitSize, ConnectionSize * Const.UnitSize);
        painter:DrawLine((8 + ConnectionSize) * Const.UnitSize, ConnectionSize * Const.UnitSize, (8 + 2 * ConnectionSize) * Const.UnitSize, 0);
        painter:DrawLine((8 + 2 * ConnectionSize) * Const.UnitSize, 0, (widthUnitCount - 1) * Const.UnitSize, 0);
        painter:DrawCircle(Const.UnitSize * (widthUnitCount - 1), Const.UnitSize, 0, Const.UnitSize, "z", false, nil, math.pi * 3 / 2, math.pi * 2);
        painter:DrawLine(Const.UnitSize * widthUnitCount, (ConnectionSize - 1) * Const.UnitSize, Const.UnitSize * widthUnitCount, Const.UnitSize * ConnectionSize);
        painter:Flush();
    end

    painter:Translate(-offsetXUnitCount * Const.UnitSize, -offsetYUnitCount * Const.UnitSize);
end

-- 绘制下边及突出部分 占据高度 4 * Const.UnitSize
function Shape:DrawNextConnection(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount, isBlockInnerConnection)
    painter:SetPen(self:GetBrush());
    
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * Const.UnitSize, offsetYUnitCount * Const.UnitSize);

    local ConnectionSize = Const.ConnectionHeightUnitCount;
    self:DrawDownEdge(painter, widthUnitCount, ConnectionSize - Const.BlockEdgeHeightUnitCount, nil, nil, isBlockInnerConnection);
    painter:Translate(0, ConnectionSize * Const.UnitSize);
    
    painter:SetPen(self:GetBrush());
    -- 下边突出部分
    painter:Translate(4 * Const.UnitSize, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, Const.UnitSize * ConnectionSize, -Const.UnitSize * ConnectionSize, Const.UnitSize * ConnectionSize, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(ConnectionSize * Const.UnitSize, 0);
    painter:DrawRect(0, 0, Const.UnitSize * 4, Const.UnitSize * ConnectionSize);
    painter:Translate(4 * Const.UnitSize, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -Const.UnitSize * ConnectionSize, Const.UnitSize * ConnectionSize, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(-(8 + ConnectionSize) * Const.UnitSize,  0);
    painter:Flush();

    -- 绘制边框
    if (self:IsDrawBorder()) then
        painter:SetPen(self:GetBrush());
        painter:DrawLine(4 * Const.UnitSize, 0, 12 * Const.UnitSize, 0);
        painter:SetPen(self:GetPen());
        painter:DrawLine(4 * Const.UnitSize, 0, (4 + ConnectionSize) * Const.UnitSize, ConnectionSize * Const.UnitSize);
        painter:DrawLine((4 + ConnectionSize) * Const.UnitSize, ConnectionSize * Const.UnitSize, (8 + ConnectionSize) * Const.UnitSize, ConnectionSize * Const.UnitSize);
        painter:DrawLine((8 + ConnectionSize) * Const.UnitSize, ConnectionSize * Const.UnitSize, (8 + 2 * ConnectionSize) * Const.UnitSize, 0);
        painter:Flush();
    end
    
    painter:Translate(0, -ConnectionSize * Const.UnitSize);
    painter:Translate(-offsetXUnitCount * Const.UnitSize, -offsetYUnitCount * Const.UnitSize);
end

-- 绘制矩形
function Shape:DrawRect(painter, leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local painter = painter or self:GetPainter();
    painter:SetPen(self:GetBrush());
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * Const.UnitSize, offsetYUnitCount * Const.UnitSize);
    painter:DrawRect(leftUnitCount * Const.UnitSize, topUnitCount * Const.UnitSize, widthUnitCount * Const.UnitSize, heightUnitCount * Const.UnitSize);
    painter:Translate(-offsetXUnitCount * Const.UnitSize, -offsetYUnitCount * Const.UnitSize);
end

-- 绘制线条
function Shape:DrawLine(painter, x1, y1, x2, y2)
    local painter = painter or self:GetPainter();
    painter:SetPen(self:GetPen());
    painter:DrawLine(x1 * Const.UnitSize, y1 * Const.UnitSize, x2 * Const.UnitSize, y2 * Const.UnitSize);
end
