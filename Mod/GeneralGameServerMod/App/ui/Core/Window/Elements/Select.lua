--[[
Title: Select
Author(s): wxa
Date: 2020/8/14
Desc: 按钮
-------------------------------------------------------
local Select = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Select.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);

local Option = commonlib.inherit(Element, {});
Option:Property("Name", "Option");
Option:Property("Value", "");
Option:Property("Label", "");
Option:Property("Text", "");
Option:Property("SelectElement");
Option:Property("BaseStyle", {
    NormalStyle = {
        width = "100%"
    }
});

function Option:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);
    self:SetLabel(self:GetAttrStringValue("label") or self:GetInnerText() or "");
    self:SetValue(self:GetAttrStringValue("value", ""));
    self:SetText(self:GetLabel());
    return self;
end

function Option:OnUpdateLayout()
	local layout, style = self:GetLayout(), self:GetStyle();
	local parentLayout = self:GetParentElement():GetLayout();
	local parentContentWidth, parentContentHeight = parentLayout:GetContentWidthHeight();
	local width, height = layout:GetWidthHeight();
	local text = self:GetLabel();

    local textWidth, textHeight = _guihelper.GetTextWidth(text, self:GetFont()), self:GetLineHeight();
    width, height = width or textWidth, height or textHeight;
    if (width < textWidth) then
        if (style["text-overflow"] == "ellipsis") then
            text = _guihelper.TrimUtf8TextByWidth(text, width - 16, self:GetFont()) .. "...";
        else
            text = _guihelper.TrimUtf8TextByWidth(text, width, self:GetFont());
        end
        self:SetText(text);    
    end

    self:GetLayout():SetWidthHeight(width, height);

    return true; 
end

function Option:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    local text = self:GetText();
    local lineHeight, fontSize = self:GetLineHeight(), self:GetFontSize();

    painter:SetPen(self:GetColor("#000000"));
    painter:SetFont(self:GetFont());
    painter:DrawText(x, y + (lineHeight - fontSize) / 2 - fontSize / 6, text);
end

function Option:OnClick()
    self:GetSelectElement():OnSelect(self);
end

local Select = commonlib.inherit(Element, NPL.export());

Select:Property("Name", "Select");
Select:Property("ListBoxElement");
Select:Property("SelectedOptionElement");
Select:Property("BaseStyle", {
    NormalStyle = {
        ["display"] = "inline-block",
        ["background-color"] = "#ffffff",
        ["width"] = "120px",
        ["height"] = "28px",
        ["padding"] = "4px 0px"
    }
});

function Select:ctor()
    self:SetName("Div");
end

function Select:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);

    local ListBox = self:CreateFromXmlNode({
        name = "div",
        attr = {
            style = "position: absolute; left: 0px; top: 0px;  max-height: 130px; width: 100%; overflow-x: hidden; background-color: #ffffff; padding: 4px 2px;",
        }
    }, window, self);
    self:SetListBoxElement(ListBox);
    self:InsertChildElement(ListBox);

    local options = self:GetAttrValue("options");
    if (options) then
        self:OnOptionsAttrValueChange(options);
    else
        -- 创建子元素
        for i, childXmlNode in ipairs(xmlNode) do
            if (type(childXmlNode) == "table" and childXmlNode.name == "option") then
                local childElement = Option:new():Init(childXmlNode, window, ListBox);
                childElement:SetSelectElement(self);
                ListBox:InsertChildElement(childElement);
            end
        end
    end

    self:OnValueAttrValueChange(self:GetAttrStringValue("value"));

    ListBox:SetVisible(false);
    return self;
end

function Select:OnAttrValueChange(attrName, attrValue)
    if (attrName == "value") then
        self:OnValueAttrValueChange(attrValue);
    elseif (attrName == "options") then
        self:OnOptionsAttrValueChange(attrValue);
    end
end

function Select:OnOptionsAttrValueChange(attrValue)
    if (type(attrValue) ~= "table") then return end
    local ListBox = self:GetListBoxElement();
    local option = self:GetSelectedOptionElement();
    local value = option and option:GetValue() or self:GetAttrStringValue("value");
    ListBox:ClearChildElement();

    self:SetSelectedOptionElement(nil);
    for _, option in ipairs(attrValue) do
        if (type(option) == "string") then option = {label = option, value = option} end
        if (type(option) == "table") then
            local childElement = Option:new():Init({name = "option", attr = {label = option.label or option.value, value = option.value or option.label}}, self:GetWindow(), ListBox);
            childElement:SetSelectElement(self);
            ListBox:InsertChildElement(childElement);
            if (childElement:GetValue() == value) then
                self:SetSelectedOptionElement(childElement);
            end
        end
    end
end

function Select:OnValueAttrValueChange(attrValue)
    self:SetSelectedOptionElement(nil);
    local ListBox = self:GetListBoxElement();
    for childElement in ListBox:ChildElementIterator() do
        if (childElement:GetValue() == attrValue) then
            self:SetSelectedOptionElement(childElement);
        end
    end
end

function Select:OnSelect(option)
    self:SetSelectedOptionElement(option);
    local value = option and option:GetValue();
    self:CallAttrFunction("onselect", nil, value);
end

function Select:OnFocusIn(event)
    self:GetListBoxElement():SetVisible(true);
    self:GetListBoxElement():UpdateLayout();
    self:OnAfterUpdateLayout();
    Select._super.OnFocusIn(self, event);
end

function Select:OnFocusOut(event)
    self:GetListBoxElement():SetVisible(false);
    Select._super.OnFocusOut(self, event);
end

function Select:OnAfterUpdateLayout()
    local width, height = self:GetSize();
    self:GetListBoxElement():SetPosition(0, (height or 0) + 2);
end

local ArrowAreaSize = 20;

function Select:RenderContent(painter)
    self:RenderArrowIcon(painter);

    local text = self:GetAttrStringValue("placeholder");
    local option = self:GetSelectedOptionElement();
    local x, y, w, h = self:GetContentGeometry();
    local fontSize = self:GetFontSize(14);

    painter:SetPen(self:GetColor("#000000"));
    painter:SetFont(self:GetFont());
    if (option) then
        text = option:GetLabel(); 
    else
        painter:SetPen("#A8A8A8"); -- placeholder color;
    end
    text = _guihelper.TrimUtf8TextByWidth(text, w - ArrowAreaSize, self:GetFont());
    painter:DrawText(x, y + (h - fontSize) / 2 - fontSize / 6, text or "");
end

local ArrowSize = 12;
local Points = {
    Down = {
        {0, ArrowSize / 4, 0},
        {ArrowSize / 2, ArrowSize * 3 / 4, 0},
        {ArrowSize / 2, ArrowSize * 3 / 4, 0},
        {ArrowSize, ArrowSize / 4, 0},
    },
    
    Up = {
        {0, ArrowSize * 3 / 4, 0},
        {ArrowSize / 2, ArrowSize / 4, 0},
        {ArrowSize / 2, ArrowSize / 4, 0},
        {ArrowSize, ArrowSize * 3 / 4, 0},
    }
}

function Select:RenderArrowIcon(painter)
    local x, y, w, h = self:GetGeometry();

    painter:Translate(x + w - ArrowAreaSize, y + (h - ArrowSize) / 2);
    painter:SetPen(self:GetColor("#000000"));
    painter:SetFont(self:GetFont());
    painter:DrawLineList(self:GetListBoxElement():IsVisible() and Points.Up or Points.Down);
    painter:Translate(-(x + w - ArrowAreaSize), -(y + (h - ArrowSize) / 2));
end
