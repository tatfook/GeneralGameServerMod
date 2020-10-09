--[[
Title: Style
Author(s): wxa
Date: 2020/8/14
Desc: 样式元素
-------------------------------------------------------
local Style = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Style.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local Style = commonlib.inherit(Element, NPL.export());

Style:Property("BaseStyle", {
	NormalStyle = {
		["display"] = "none",
	}
});

function Style:ctor()
    self:SetName("Style");
    self:SetVisible(false);
end

-- public:
function Style:Init(xmlNode, window)
    self:SetTagName(xmlNode.name);
	self:SetAttr(xmlNode.attr);
	self:SetXmlNode(xmlNode);
    self:SetWindow(window);
    self:SetStyle(self:CreateStyle());

    local code = "";
    for i = 1, #xmlNode do
        if (type(xmlNode[i]) == "string") then
            code = code .. xmlNode[i];
        end
    end

    self.sheet = self:GetWindow():GetStyleManager():AddStyleSheetByString(code);
    
	return self;
end


function Style:Destroy()
    self:GetWindow():GetStyleManager():RemoveStyleSheet(code);
end
