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
local InputElement = NPL.load("./Input.lua");

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

function Option:OnMouseDown(event)
    Option._super.OnMouseDown(self, event);
    self:GetSelectElement():OnSelect(self);
    event:accept();
    self:CaptureMouse();
end

function Option:OnMouseUp(event)
    Option._super.OnMouseUp(self, event);
    event:accept();
    self:ReleaseMouseCapture();
end

-- SelectListBox
local ListBox = commonlib.inherit(Element, {});
ListBox:Property("Name", "ListBox");

-- Select
local Select = commonlib.inherit(Element, NPL.export());

Select:Property("Name", "Select");
Select:Property("Label", "");
Select:Property("Value", "");
Select:Property("ListBoxElement");
Select:Property("InputBoxElement");
Select:Property("SelectedOptionElement");
Select:Property("BaseStyle", {
    NormalStyle = {
        ["display"] = "inline-block",
        ["background-color"] = "#ffffff",
        ["width"] = "120px",
        ["height"] = "30px",
        ["padding"] = "2px 4px",
        ["border"] = "1px solid #cccccc",
    }
});

function Select:ctor()
    self:SetCanFocus(true);
end

function Select:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);

    local ListBox = ListBox:new():Init({
        name = "ListBox",
        attr = {
            style = "position: absolute; left: 0px; top: 105%;  max-height: 130px; width: 100%; overflow-x: hidden; overflow-y: auto; background-color: #ffffff; padding: 4px 2px;",
        }
    }, window, self);
    local InputBox = InputElement:new():Init({
        name = "input",
        attr = {
            style = "position: absolute; left: 0px; top: 0px; right: 0px; bottom: 0px; border: none; background-color: #ffffff00; height: 100%; width: 100%;",
            onblur = function()
                self:OnFocusOut();
            end,
            ["onkeydown.enter"] = function(value)
                value = self:GetValueByLabel(value);
                self:SetValue(value);
                self:SetLabel(self:GetLabelByValue(value));
                self:SetFocus(nil);
                self:CallAttrFunction("onselect", nil, self:GetValue(), self:GetLabel());
                self:CallAttrFunction("onchange", nil, self:GetValue(), self:GetLabel());
            end
        }
    }, window, self);
    self:SetListBoxElement(ListBox);
    self:SetInputBoxElement(InputBox);
    self:InsertChildElement(InputBox);
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

    InputBox:SetVisible(false);
    ListBox:SetVisible(false);

    return self;
end

function Select:IsAllowCreate()
    return self:GetAttrBoolValue("AllowCreate");
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
            local childElement = Option:new():Init({name = "option", attr = {label = option[1] or option.label or option.value, value = option[2] or option[1] or option.value or option.label}}, self:GetWindow(), ListBox);
            childElement:SetSelectElement(self);
            ListBox:InsertChildElement(childElement);
            if (childElement:GetValue() == value) then
                self:SetValue(childElement:GetValue());
                self:SetLabel(childElement:GetLabel());
                self:SetSelectedOptionElement(childElement);
            end
        end
    end
end

function Select:OnValueAttrValueChange(attrValue)
    self:SetSelectedOptionElement(nil);
    local ListBox = self:GetListBoxElement();
    for _, childElement in ipairs(ListBox.childrens) do
        if (childElement:GetValue() == attrValue) then
            self:SetValue(childElement:GetValue());
            self:SetLabel(childElement:GetLabel());
            return self:SetSelectedOptionElement(childElement);
        end
    end
    self:SetValue(attrValue);
    self:SetLabel(attrValue);
end

function Select:GetLabelByValue(value)
    local ListBox = self:GetListBoxElement();
    for _, option in ipairs(ListBox.childrens) do
        if (value == option:GetValue()) then return option:GetLabel() end
    end
    return value;
end

function Select:GetValueByLabel(label)
    local ListBox = self:GetListBoxElement();
    for _, option in ipairs(ListBox.childrens) do
        if (label == option:GetLabel()) then return option:GetValue() end
    end
    return label;
end

function Select:FilterOptions(filter)
    local ListBox = self:GetListBoxElement();
    for _, option in ipairs(ListBox.childrens) do
        local value = option:GetValue();
        if (not filter or filter == "") then option:SetVisible(true)
        elseif (type(filter) == "string" and (string.find(value, filter, 1, true))) then option:SetVisible(true)
        elseif (type(filter) == "function" and filter(value)) then option:SetVisible(true) 
        else option:SetVisible(false) end
    end
    ListBox:UpdateLayout();
end

function Select:OnSelect(option)
    self:SetSelectedOptionElement(option);
    local value = option and option:GetValue();
    local label = option and option:GetLabel();
    self:SetValue(value);
    self:SetLabel(label);
    self:SetFocus(nil);
    self:OnFocusOut();
    self:CallAttrFunction("onselect", nil, value, label);
    self:CallAttrFunction("onchange", nil, value, label);
end

function Select:OnFocusIn(event)
    if (self:IsAllowCreate()) then
        self:GetInputBoxElement():SetAttrValue("value", self:GetLabel());
        -- self:GetInputBoxElement():SetAttrValue("value", "");
        self:GetInputBoxElement():FocusIn();
        self:GetInputBoxElement():SetVisible(true);
        self:GetInputBoxElement():UpdateLayout();
    end
    self:GetListBoxElement():SetVisible(true);
    self:GetListBoxElement():UpdateLayout();
    Select._super.OnFocusIn(self, event);
end

function Select:OnFocusOut(event)
    if (self:GetInputBoxElement():IsFocus()) then return end

    self:GetInputBoxElement():SetVisible(false);
    self:GetListBoxElement():SetVisible(false);
    Select._super.OnFocusOut(self, event);
end

local ArrowAreaSize = 20;

function Select:RenderContent(painter)
    self:RenderArrowIcon(painter);

    if (self:GetInputBoxElement():GetVisible()) then return end

    local text = self:GetAttrStringValue("placeholder");
    local x, y, w, h = self:GetContentGeometry();

    painter:SetPen(self:GetColor("#000000"));
    painter:SetFont(self:GetFont());
    if (self:GetLabel() ~= "") then
        text = self:GetLabel(); 
    else
        painter:SetPen("#A8A8A8"); -- placeholder color;
    end
    text = _guihelper.TrimUtf8TextByWidth(text, w - ArrowAreaSize, self:GetFont());
    painter:DrawText(x, y + (h - self:GetSingleLineTextHeight()) / 2, text or "");
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
