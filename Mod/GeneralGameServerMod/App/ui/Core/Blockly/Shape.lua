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

local Const = NPL.load("./Const.lua", IsDevEnv);
local Shape = NPL.export();

local Triangle = {{0,0,0}, {0,0,0}, {0,0,0}};       -- 三角形
local UnitSize = Const.UnitSize;

-- 绘制上边缘
function Shape:DrawUpEdge(painter, widthUnitCount, fillHeightUnitCount, offsetXUnitCount, offsetYUnitCount)
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    fillHeightUnitCount = fillHeightUnitCount or 0;
    painter:DrawRect(UnitSize, 0, (widthUnitCount - 2) * UnitSize, UnitSize);
    painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi / 2, math.pi);
    painter:DrawCircle(UnitSize * (widthUnitCount - 1), -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:DrawRect(0, UnitSize, widthUnitCount * UnitSize, UnitSize * (Const.BlockEdgeHeightUnitCount - 1));
    painter:DrawRect(0, Const.BlockEdgeHeightUnitCount * UnitSize, widthUnitCount * UnitSize, UnitSize * fillHeightUnitCount);
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制下边缘
function Shape:DrawDownEdge(painter, widthUnitCount, fillHeightUnitCount, offsetXUnitCount, offsetYUnitCount)
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    fillHeightUnitCount = fillHeightUnitCount or 0;
    painter:DrawRect(0, 0, widthUnitCount * UnitSize, UnitSize * fillHeightUnitCount);
    painter:Translate(0, fillHeightUnitCount * UnitSize);
    painter:DrawRect(0, 0, widthUnitCount * UnitSize, UnitSize * (Const.BlockEdgeHeightUnitCount - 1));
    local OffsetY = Const.BlockEdgeHeightUnitCount - 1;
    painter:DrawRect(UnitSize, OffsetY * UnitSize, (widthUnitCount - 2) * UnitSize, UnitSize);
    painter:DrawCircle(UnitSize, -OffsetY * UnitSize, 0, UnitSize, "z", true, nil, math.pi, math.pi * 3 / 2);
    painter:DrawCircle(UnitSize * (widthUnitCount - 1), -OffsetY * UnitSize, 0, UnitSize, "z", true, nil, math.pi * 3 / 2, math.pi * 2);
    painter:Translate(0, -fillHeightUnitCount * UnitSize);

    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制左边缘
function Shape:DrawLeftEdge(painter, heightUnitCount, fillWidthUnitCount, offsetXUnitCount, offsetYUnitCount)
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    fillWidthUnitCount = fillWidthUnitCount or 0;
    painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi / 2, math.pi);
    painter:DrawRect(0, UnitSize, UnitSize, (heightUnitCount - 2) * UnitSize);
    painter:DrawCircle(UnitSize, -(heightUnitCount - 1) * UnitSize, 0, UnitSize, "z", true, nil, math.pi, math.pi * 3 / 2);
    painter:DrawRect(UnitSize, 0, (Const.BlockEdgeWidthUnitCount - 1) * UnitSize, heightUnitCount * UnitSize);
    painter:DrawRect(Const.BlockEdgeWidthUnitCount * UnitSize, 0, fillWidthUnitCount * UnitSize, heightUnitCount * UnitSize);

    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制右边缘
function Shape:DrawRightEdge(painter, heightUnitCount, fillWidthUnitCount, offsetXUnitCount, offsetYUnitCount)
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    fillWidthUnitCount = fillWidthUnitCount or 0;
    painter:DrawRect(0, 0, fillWidthUnitCount * UnitSize, heightUnitCount * UnitSize);
    painter:Translate(fillWidthUnitCount * UnitSize, 0);
    painter:DrawRect(0, 0, (Const.BlockEdgeWidthUnitCount - 1) * UnitSize, heightUnitCount * UnitSize);
    local OffsetX = Const.BlockEdgeWidthUnitCount - 1;
    painter:DrawCircle(OffsetX * UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:DrawRect(OffsetX * UnitSize, UnitSize, UnitSize, (heightUnitCount - 2) * UnitSize);
    painter:DrawCircle(OffsetX * UnitSize, -(heightUnitCount - 1) * UnitSize, 0, UnitSize, "z", true, nil, math.pi * 3 / 2, math.pi * 2);
    painter:Translate(-fillWidthUnitCount * UnitSize, 0);

    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制上边及凹陷部分 占据高度 2 * UnitSize
function Shape:DrawPrevConnection(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount)
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi / 2, math.pi);
    painter:DrawRect(UnitSize, 0, UnitSize * 3, UnitSize);
    painter:DrawRect(0, UnitSize, UnitSize * 4, UnitSize);
    painter:Translate(UnitSize * 4, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -UnitSize * 2, UnitSize * 2, -UnitSize * 2;
    painter:DrawTriangleList(Triangle);
    painter:Translate(UnitSize * 6, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, -UnitSize * 2, UnitSize * 2, -UnitSize * 2, UnitSize * 2, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(UnitSize * 2, 0);
    local remainSize = widthUnitCount - 13;
    painter:DrawRect(0, 0, UnitSize * remainSize, UnitSize);
    painter:DrawRect(0, UnitSize, UnitSize * (remainSize + 1), UnitSize);
    painter:Translate(UnitSize * remainSize, 0);
    painter:DrawCircle(0, -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:Translate(-(widthUnitCount - 1) * UnitSize, 0);

    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

-- 绘制下边及突出部分 占据高度 4 * UnitSize
function Shape:DrawNextConnection(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount)
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);

    -- 绘制下边缘
    self:DrawDownEdge(painter, widthUnitCount, Const.ConnectionHeightUnitCount - Const.BlockEdgeHeightUnitCount);
    painter:Translate(0, Const.ConnectionHeightUnitCount * UnitSize);

    -- 下边突出部分
    painter:Translate(4 * UnitSize, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, UnitSize * 2, -UnitSize * 2, UnitSize * 2, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(2 * UnitSize, 0);
    painter:DrawRect(0, 0, UnitSize * 4, UnitSize * 2);
    painter:Translate(4 * UnitSize, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -UnitSize * 2, UnitSize * 2, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(-10 * UnitSize,  0);
    
    painter:Translate(0, -Const.ConnectionHeightUnitCount * UnitSize);
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end
