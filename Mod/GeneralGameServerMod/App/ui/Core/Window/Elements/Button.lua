--[[
Title: Button
Author(s): wxa
Date: 2020/8/14
Desc: 按钮
-------------------------------------------------------
local Button = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Button.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");

local Element = NPL.load("../Element.lua", IsDevEnv);
local Button= commonlib.inherit(Element, NPL.export());

function Button:ctor()
	self:SetTabIndex(0);
end

function Button:createFromXmlNode(o)
    o = self:new(o);
    

	return o;
end

function Button:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	local polygonStyle = self:GetAttributeWithCode("polygonStyle", nil, true);
	local direction = self:GetAttributeWithCode("direction", nil, true);
	local hotkey = self:GetAttributeWithCode("hotkey", nil, true);
	if(hotkey) then
		local page = self:GetPageCtrl();
		page:AddHotkeyNode(self, hotkey);
	end

	local _this = self.control;
	if(not _this) then
		_this = Button:new():init(parentElem);
		_this:SetPolygonStyle(polygonStyle);
		_this:SetDirection(direction);
		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end
	_this:ApplyCss(css);
	_this:SetText(tostring(self:GetAttributeWithCode("value", nil, true) or ""));
	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
	_this:Connect("clicked", self, self.OnClick, "UniqueConnection")
	Button._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)
end



function Button:OnBeforeUpdateChildElementLayout(elementLayout, parentElementLayout)
    if(not self.control) then return end
    
    local paddingLeft, paddingTop, paddingRight, paddingBottom = elementLayout:GetPaddings();
    local width, height = elementLayout:GetWidhtHeight();
    
    width = width or (self.control:CalculateTextWidth() + paddingLeft + paddingRight);
    height = height or (self.control:CalculateTextHeight() + paddingTop + paddingBottom);
    elementLayout:SetWidthHeight(width, height);

    return true;
end

function Button:OnClick()
	local onclick = self:GetAttributeWithCode("onclick", nil, true);
    if(type(onclick) ~= "function") then return end
    onclick();
end

