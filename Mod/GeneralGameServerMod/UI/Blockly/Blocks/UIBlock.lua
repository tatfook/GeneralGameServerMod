--[[
Title: UIBlock
Author(s): wxa
Date: 2021/3/1
Desc: Lua
use the lib:
-------------------------------------------------------
local UIBlock = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Blocks/UIBlock.lua");
-------------------------------------------------------
]]


local UIBlock = NPL.export();

local function GetUI(cache)
    cache.UI = cache.UI or {};
    return cache.UI;
end

local function GetStyles(cache)
    cache.UI = cache.UI or {};
    cache.UI.styles = cache.UI.styles or {};
    return cache.UI.styles;
end

local function GetStyle(cache, styleName)
    local styles = GetStyles(cache);
    return styles[styleName];
end

local function GetAttrs(cache)
    cache.UI = cache.UI or {};
    cache.UI.attrs = cache.UI.attrs or {};
    return cache.UI.attrs;
end

local function GetAttr(cache, attrName)
    local attrs = GetAttrs(cache);
    return attrs[attrName];
end

local function GetSelectors(cache)
    cache.UI = cache.UI or {};
    cache.UI.selectors = cache.UI.selectors or {};
    return cache.UI.selectors;
end

local function InitCode(cache)
    local UI = GetUI(cache);
    if (not UI.inited) then
        UI.inited = true;
        if (IsDevEnv) then
            return 'local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua", true)\n';
        else
            return 'local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua")\n';
        end
    end
    return "";
end


local UI_Style_Item = {};
local Style_Key_Options = {
    {"宽", "width"}, 
    {"高", "height"}, 
    {"显示方式", "display"},
    {"弹性布局方向", "flex-direction"},
    {"主轴排列方式", "justify-content"},
    {"辅助排列方式", "align-items"},
    {"字体大小", "font-size"},
}
local Style_Value_Options = {
    ["display"] = { "flex", "block", "inline-block", "inline"},
    ["flex-direction"] = { "row", "column"},
    ["justify-content"] = {"center", "space-between", "space-around","flex-start", "flex-end"},
    ["align-items"] = {"center", "space-between", "space-around","flex-start", "flex-end"},
    ["font-size"] = {"10px", "12px", "14px", "16px", "18px", "20px", "24px", "28px", "30px", "36px", "40px", "50px"},
}

local function Style_Value_Options_Func(field)
    local block = field:GetBlock();
    local defaultOptions = {};
    if (not block) then return defaultOptions end
    local key = block:GetFieldValue("key") or "";
    return Style_Value_Options[key] or defaultOptions;
end

function UI_Style_Item.OnInit(option)
    local arg = option.arg;
    if (type(arg) ~= "table") then return end
    for _, field in ipairs(arg) do
        if (field.name == "key") then
            field.options = Style_Key_Options;
            field.isAllowCreate = true;
        end
        if (field.name == "value") then
            field.options = Style_Value_Options_Func;
            field.isAllowCreate = true;
        end
    end
end

local UI_Style_Create = {};
function UI_Style_Create.ToCode(block)
    local styles = GetStyles(block:GetToCodeCache());
    local fieldStyleName = block:GetFieldValue("style");
    styles[fieldStyleName] = "";
    return nil;
end

local UI_Style_Insert = {};
function UI_Style_Insert.ToCode(block)
    local styles = GetStyles(block:GetToCodeCache());
    local fieldStyleName = block:GetFieldValue("style");
    local fieldStyleItem = block:GetFieldValue("styleItem");
    styles[fieldStyleName] = styles[fieldStyleName] or "";
    styles[fieldStyleName] = styles[fieldStyleName] .. " " .. fieldStyleItem;
    return nil;
end

local UI_Style_Get = {};
function UI_Style_Get.ToCode(block)
    return nil;
end

local UI_Style_Set_Selector = {};
function UI_Style_Set_Selector.ToCode(block)
    local fieldSelector = block:GetFieldValue("selector");
    local fieldStyles = block:GetFieldValue("styles");
    local selectors = GetSelectors(block:GetToCodeCache());
    selectors[fieldSelector] = fieldStyles;
    return nil;
end

local UI_Attr_Create = {};
function UI_Attr_Create.ToCode(block)
    local attrs = GetAttrs(block:GetToCodeCache());
    local fieldAttrName = block:GetFieldValue("attrs");
    styles[fieldStyleName] = "";
    return nil;
end

local UI_Attr_Insert = {};
function UI_Attr_Insert.ToCode(block)
    local attrs = GetAttrs(block:GetToCodeCache());
    local fieldAttrName = block:GetFieldValue("attrs");
    local fieldAttrItem = block:GetFieldValue("attr");
    attrs[fieldAttrName] = attrs[fieldAttrName] or "";
    attrs[fieldAttrName] = attrs[fieldAttrName] .. " " .. fieldAttrItem;
    return nil;
end

local UI_Attr_Get = {};
function UI_Attr_Get.ToCode(block)
    return nil;
end

local UI_Attr_Get_Style = {};
function UI_Attr_Get_Style.ToCode(block)
    local styles = GetStyles(block:GetToCodeCache());
    local fieldStyleName = block:GetFieldValue("style");
    styles[fieldStyleName] = styles[fieldStyleName] or "";
    return string.format('style="%s"', styles[fieldStyleName]);
end


local UI_Element = {};
function UI_Element.ToCode(block)
    local cache = block:GetToCodeCache();
    local fieldTag = block:GetFieldValue("tag");
    local fieldAttrName = block:GetFieldValue("attrs");
    local fieldAttr = GetAttr(cache, fieldAttrName) or fieldAttrName;
    return string.format('<%s %s></%s>\n', fieldTag, fieldAttr, fieldTag);
end

local UI_Elements = {};
function UI_Elements.ToCode(block)
    local cache = block:GetToCodeCache();
    local fieldTag = block:GetFieldValue("tag");
    local fieldAttrName = block:GetFieldValue("attrs");
    local fieldContent = block:GetValueAsString("content");
    local fieldAttr = GetAttr(cache, fieldAttrName) or fieldAttrName;
    return string.format('<%s %s>\n%s</%s>\n', fieldTag, fieldAttr, fieldContent, fieldTag);
end

local UI_Element_Text = {};
function UI_Element_Text.ToCode(block)
    local cache = block:GetToCodeCache();
    local fieldTag = block:GetFieldValue("tag");
    local fieldAttrName = block:GetFieldValue("attrs");
    local fieldText = block:GetValueAsString("text");
    local fieldAttr = GetAttr(cache, fieldAttrName) or fieldAttrName;
    return string.format('<%s %s>%s</%s>\n', fieldTag, fieldAttr, fieldText, fieldTag);
end

local UI_Component_Register = {};
function UI_Component_Register.ToCode(block)
    local cache = block:GetToCodeCache();
    local text = "";
    local fieldWdith = block:GetFieldValue("width");
    local fieldHeight = block:GetFieldValue("height");
    local fieldHtml = block:GetFieldValue("html");
    text = text .. string.format('<template style="width:%s; height: %s">\n%s</template>\n', fieldWdith, fieldHeight, fieldHtml);

    local fieldScript = block:GetFieldValue("script");
    local fieldSrc = block:GetFieldValue("src");
    text = text .. string.format('<script src="%s">\n%s</script>', fieldSrc or "", fieldScript);

    local selectors = GetSelectors(cache);
    local selectorText = "";
    for selector, text in pairs(selectors) do
        selectorText = selectorText .. string.format("%s {%s}\n", selector, text);
    end
    text = text .. "\n<style scoped=true>\n" .. selectorText .. "</style>";

    local UI = GetUI(cache);
    local code = InitCode(cache)
    local fieldName = block:GetFieldValue("name");
    code = code .. string.format('Page.RegisterComponent("%s", {template = [====[\n%s\n]====]})', fieldName, text);
    return code;
end

local UI_Window_Register = {};
function UI_Window_Register.ToCode(block)
    local fieldName = block:GetFieldValue("name");
    local fieldAlignment = block:GetFieldValue("alignment");
    local fieldLeft = block:GetFieldValue("left");
    local fieldTop = block:GetFieldValue("top");
    local fieldWidth = block:GetFieldValue("width");
    local fieldHeight = block:GetFieldValue("height");
    local fieldHtml = block:GetFieldValue("html");

    local cache = block:GetToCodeCache();
    local code = InitCode(cache);
    code = code .. string.format('Page.RegisterWindow({windowName = "%s", alignment = "%s", x = "%s", y = "%s", width = "%s", height = "%s", html = "<%s></%s>"})\n', fieldName, fieldAlignment, fieldLeft, fieldTop, fieldWidth, fieldHeight, fieldHtml, fieldHtml);
    return code;
end

UIBlock.UI_Elements = UI_Elements;
UIBlock.UI_Element = UI_Element;
UIBlock.UI_Element_Text = UI_Element_Text;
UIBlock.UI_Style_Item = UI_Style_Item;
UIBlock.UI_Style_Create = UI_Style_Create;
UIBlock.UI_Style_Insert = UI_Style_Insert;
UIBlock.UI_Style_Get = UI_Style_Get;
UIBlock.UI_Style_Set_Selector = UI_Style_Set_Selector;
UIBlock.UI_Attr_Get_Style = UI_Attr_Get_Style;
UIBlock.UI_Attr_Create = UI_Attr_Create;
UIBlock.UI_Attr_Insert = UI_Attr_Insert;
UIBlock.UI_Attr_Get = UI_Attr_Get;
UIBlock.UI_Component_Register = UI_Component_Register;
UIBlock.UI_Window_Register = UI_Window_Register;