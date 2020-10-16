--[[
Title: Button
Author(s): wxa
Date: 2020/8/14
Desc: 按钮
-------------------------------------------------------
local Canvas = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Canvas.lua");
-------------------------------------------------------
]]
local Element = NPL.load("../Element.lua", IsDevEnv);
local Canvas = commonlib.inherit(Element, NPL.export());

local pen = {width = 2, color = "#000000"};
local lines, points = {}, {};

Canvas:Property("Name", "Canvas");
Canvas:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["display"] = "inline-block",
        ["width"] = "220px",
        ["height"] = "220px",
        ["padding"] = "10px",
    }
})
function Canvas:ctor()
    self:SetName("Canvas");
end

-- 绘制内容
function Canvas:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    painter:Translate(x, y);

    painter:SetPen(pen);

    points[1] = {100, 0, 0};
    points[2] = {0, -200, 0};
    points[3] = {200, -200, 0};

    lines[1] = points[1];
    lines[2], lines[3] = points[2], points[2];
    lines[4] = points[3];
    lines[4], lines[5] = points[3], points[3];
    lines[6] = points[1];

    -- 此函数 y > 0 向上  y < 0 向下
    painter:DrawTriangleList(points);
    -- painter:DrawLineList(lines);

    painter:Translate(-x, -y);
end
