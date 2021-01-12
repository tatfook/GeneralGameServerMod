--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 输入字段
use the lib:
-------------------------------------------------------
local Select = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Select.lua");
-------------------------------------------------------
]]
local DivElement = NPL.load("../../Window/Elements/Div.lua", IsDevEnv);
local InputElement = NPL.load("../../Window/Elements/Input.lua", IsDevEnv);
local SelectElement = NPL.load("../../Window/Elements/Select.lua", IsDevEnv);

local Const = NPL.load("../Const.lua", IsDevEnv);
local Input = NPL.load("./Input.lua", IsDevEnv);

local Select = commonlib.inherit(Input, NPL.export());

Select:Property("AllowNewOption", false, "IsAllowNewOption");  -- 是否允许新增选项

function Select:Init(block, opt)
    Select._super.Init(self, block, opt);

    self:SetLabel(self:GetLabelByValue(self:GetValue()));
    self:SetValue(self:GetValueByLablel(self:GetLabel()));

    self:SetAllowNewOption(opt.allowNewOption == true and true or false);
    
    return self;
end

function Select:GetOptions()
    local option = self:GetOption();
    local options = type(option.options) == "table" and option.options or {};
    if (type(option.options) == "function") then options = option.options() end
    return options;
end

function Select:GetValueByLablel(label)
    local options = self:GetOptions();
    for _, option in ipairs(options) do
        if (option[1] == label or option.label == label) then return option[2] or option.value end
    end
    return options[1] and (options[1][2] or options[1].value);
end

function Select:GetLabelByValue(value)
    local options = self:GetOptions();
    for _, option in ipairs(options) do
        if (option[2] == value or option.value == value) then return option[1] or option.label end
    end
    return options[1] and (options[1][1] or options[1].label);
end

function Select:GetFieldEditElement(parentElement)
    local window = parentElement:GetWindow();
    local divEl = DivElement:new():Init({
        name = "div",
        attr = {
            style = "width: 100%; height: 100%; font-size: 14px;"
        }
    }, window, parentElement);

    local selectEl = SelectElement:new():Init({
        name = "select",
        attr = {
            style = "width: 100%; height: 100%;",
        },
    }, window, divEl);

    selectEl:SetCanFocus(false);
    selectEl:SetAttrValue("value", self:GetValue());
    selectEl:SetAttrValue("options", self:GetOptions());
    selectEl:SetAttrValue("onselect", function(value, label)
        self:SetValue(value);
        self:SetLabel(label);
        self:FocusOut();
    end);

    divEl:InsertChildElement(selectEl);

    if (self:IsAllowNewOption()) then
        local inputEl = InputElement:new():Init({
            name = "input",
            attr = {
                style = "position: absolute; left: 0px; top: 0px; width: 100%; height: 100%",
                value = self:GetValue(),
            }
        }, window, divEl);
        inputEl:SetAttrValue("onkeydown.enter", function()
            local value = inputEl:GetValue();
            self:SetValue(value);
            self:SetLabel(value);
            self:FocusOut();
        end);
        inputEl:SetAttrValue("onchange", function()
            local value = inputEl:GetValue();
            selectEl:FilterOptions(value);
        end)
    
        -- inputEl:SetCanFocus(false);
        divEl:InsertChildElement(inputEl);
    
        self.inputEl = inputEl;
    end

    self.divEl, self.selectEl = divEl, selectEl;
    return divEl;
end

function Select:OnBeginEdit()
    if (self.selectEl) then self.selectEl:OnFocusIn() end
    if (self.inputEl) then self.inputEl:FocusIn() end
end

function Select:OnEndEdit()
    if (self.selectEl) then self.selectEl:OnFocusOut() end
    if (self.inputEl) then self.inputEl:FocusOut() end
end
