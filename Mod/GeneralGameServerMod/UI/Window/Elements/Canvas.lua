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

Canvas:Property("Name", "Canvas");
Canvas:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["display"] = "inline-block",
        ["width"] = "100%",
        ["height"] = "100%",
    }
});

function Canvas:ctor()
end

-- 绘制内容
function Canvas:RenderContent(painter)
    self:CallAttrFunction("onrender", nil, self, painter);
end
