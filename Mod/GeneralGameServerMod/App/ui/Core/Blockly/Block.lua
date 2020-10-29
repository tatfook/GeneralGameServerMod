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

-- local UnitSize = 4;                                 -- 一个单元格4px
local UnitSize = 20;                             -- 一个单元格4px
local Triangle = {{0,0,0}, {0,0,0}, {0,0,0}};       -- 三角形

Block:Property("Blockly");
Block:Property("Output");                   -- 输出链接
Block:Property("PreviousStatement");        -- 上一条语句  nil "null", "string", "number", "boolean", ["string"]
Block:Property("NextStatement");            -- 下一条语句

function Block:ctor()
    self.inputs = {};                       -- 块内输入
    self.outputConnection = nil;
    self.topConnection = nil;
    self.bottomConnection = nil;
end

function Block:Init(blockly, opt)
    self:SetBlockly(blockly);
    self:SetOutput(opt.output);
    self:SetPreviousStatement(opt.previousStatement);
    self:SetNextStatement(opt.nextStatement);
    return self;
end

function Block:GetUnitSize()
    return self:GetBlockly():GetUnitSize();
end


function Block:RenderInputs(painter)
    local maxInputWidthUnitCount, maxInputHeightUnitCount = 0, 0;
    for _, input in ipairs(self.inputs) do
        local inputWidthUnitCount, inputHeightUnitCount = input:Render(painter);
        maxInputWidthUnitCount = math.max(maxInputWidthUnitCount, inputWidthUnitCount);
        maxInputHeightUnitCount = math.max(maxInputHeightUnitCount, inputHeightUnitCount);
    end
    return maxInputWidthUnitCount, maxInputHeightUnitCount;
end

function Block:Render(painter)
    painter:SetPen("#ff0000");
    local WidthUnitCount = 20;
    -- 绘制凹陷部分
    if (self:GetPreviousStatement()) then
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
    else
        painter:DrawRect(UnitSize, 0, (WidthUnitCount - 2) * UnitSize, UnitSize);
        painter:DrawRect(0, UnitSize, WidthUnitCount * UnitSize, UnitSize);
        painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi / 2, math.pi);
        painter:DrawCircle(UnitSize * (WidthUnitCount - 1), -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);
    end

    painter:Translate(0, 2 * UnitSize);   -- 上边
    local inputWidthUnitCount, inputHeightUnitCount = self:RenderInputs(painter);
    painter:DrawRect(0, 0, WidthUnitCount * UnitSize, 8 * UnitSize);
    painter:Translate(0, 8 * UnitSize);   -- 内容区

    -- 底部
    painter:DrawRect(0, 0, WidthUnitCount * UnitSize, UnitSize);
    painter:DrawRect(UnitSize, UnitSize, (WidthUnitCount - 2) * UnitSize, UnitSize);
    painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi, math.pi * 3 / 4);
    painter:DrawCircle(UnitSize * (WidthUnitCount - 1), -UnitSize, 0, UnitSize, "z", true, nil, math.pi * 3 / 4, math.pi * 2);
    painter:Translate(0, 2 * UnitSize);   -- 下边   offsetY = 12 * UnitSize

    -- 绘制突出部分
    if (self:GetNextStatement()) then
        painter:Translate(4 * UnitSize, 0);
        Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, UnitSize * 2, -UnitSize * 2, UnitSize * 2, 0;
        painter:DrawTriangleList(Triangle);
        painter:Translate(2 * UnitSize, 0);
        painter:DrawRect(0, 0, UnitSize * 4, UnitSize * 2);
        painter:Translate(4 * UnitSize, 0);
        Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -UnitSize * 2, UnitSize * 2, 0;
        painter:DrawTriangleList(Triangle);
        painter:Translate(-12 * UnitSize, 0);
    end

    painter:Translate(-12 * UnitSize, -12 * UnitSize);
end
