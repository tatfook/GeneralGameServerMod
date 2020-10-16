--[[
Title: Radio
Author(s): wxa
Date: 2020/8/14
Desc: 按钮
-------------------------------------------------------
local Radio = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Radio.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local Radio = commonlib.inherit(Element, NPL.export());

Radio:Property("Name", "Radio");
Radio:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["display"] = "inline-block",
        ["width"] = "20px",
        ["height"] = "20px",
        ["padding"] = "2px",
    }
});

function Radio:ctor()
    self.checked = false;
end

function Radio:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);

    self.name = self:GetAttrValue("name", "");
    self.value = self:GetAttrValue("value");

    return self;
end

function Radio:OnClick(event)
    self.checked = not self.checked;
    Radio._super.OnClick(self, event);
end

function Radio:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    local radius = math.min(w, h) / 2;
    local cx, cy = x + radius, y + radius;
    
    painter:Translate(cx, cy);
    painter:SetPen("#b5b5b5");
	painter:DrawCircle(0, 0, 0, radius, "z", true);

	painter:SetPen("#dedede");
	painter:DrawCircle(0, 0, 0, radius - 2, "z", true);

    if (self.checked) then
        painter:SetPen("#666666");
		painter:DrawCircle(0, 0, 0, radius-3, "z", true);
    end

    if(self:IsHover()) then
        painter:SetPen("#ffffff33");
        painter:DrawCircle(0, 0, 0, radius, "z");
    end

	painter:Translate(-cx, -cy);
end
	

	
