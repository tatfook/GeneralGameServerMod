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
        ["width"] = "100%",
        ["height"] = "100%",
    }
})
function Canvas:ctor()
    self:SetName("Canvas");
end

-- 绘制内容
function Canvas:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();

    -- print(x, y, w, h)
    painter:Translate(x, y);
    painter:SetPen("#00ff00");
    painter:DrawText(0, 0, "hello\nworld\n");
    painter:DrawText(0, 0, "hello\nworld\n");
    -- painter:SetBrush({texture="Texture/Aries/Creator/keepwork/ggs/test.jpg"})
    -- painter:DrawCircle(50, -50, 0, 50, "z", true);
    painter:Translate(-x, -y);
end
