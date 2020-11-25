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


local Shape = NPL.export();

local Triangle = {{0,0,0}, {0,0,0}, {0,0,0}};       -- 三角形

function Shape:DrawPrevConnection(painter, opts)
    local UnitSize, WidthUnitCount = opts.UnitSize, opts.WidthUnitCount;
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
    local remainSize = WidthUnitCount - 13;
    painter:DrawRect(0, 0, UnitSize * remainSize, UnitSize);
    painter:DrawRect(0, UnitSize, UnitSize * (remainSize + 1), UnitSize);
    painter:Translate(UnitSize * remainSize, 0);
    painter:DrawCircle(0, -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);
    painter:Translate(-(WidthUnitCount - 1) * UnitSize, 0);
end

function Shape:DrawNextConnection(painter, opts)
    local UnitSize, WidthUnitCount = opts.UnitSize, opts.WidthUnitCount;

    -- 下边框
    painter:DrawRect(0, 0, WidthUnitCount * UnitSize, UnitSize);
    painter:DrawRect(UnitSize, UnitSize, (WidthUnitCount - 2) * UnitSize, UnitSize);
    painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi, math.pi * 3 / 4);
    painter:DrawCircle(UnitSize * (WidthUnitCount - 1), -UnitSize, 0, UnitSize, "z", true, nil, math.pi * 3 / 4, math.pi * 2);
    painter:Translate(0, 2 * UnitSize);   -- 下边   offsetY = 12 * UnitSize
    
    -- 下边突出部分
    painter:Translate(4 * UnitSize, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, UnitSize * 2, -UnitSize * 2, UnitSize * 2, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(2 * UnitSize, 0);
    painter:DrawRect(0, 0, UnitSize * 4, UnitSize * 2);
    painter:Translate(4 * UnitSize, 0);
    Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -UnitSize * 2, UnitSize * 2, 0;
    painter:DrawTriangleList(Triangle);
    painter:Translate(-10 * UnitSize,  -2 * UnitSize);
end
