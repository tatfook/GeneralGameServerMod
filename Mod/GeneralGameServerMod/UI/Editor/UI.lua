
local GlobalScope = GetGlobalScope();

_G.WindowElement = nil;
_G.CurrentElement = nil;
_G.ListItemMap = {};

_G.StyleNameList = {
    "width", "height", "left", "top", "right", "bottom", "display", "position", "font-size", "color", "background", "background-color",
    "margin-top", "margin-right", "margin-bottom", "margin-left", "padding-top", "padding-right", "padding-bottom", "padding-left", 
};

local ElementId = 0;

WindowDataItem = {id = 0, text = ""};
GlobalScope:Set("CurrentElementId", nil);
GlobalScope:Set("CurrentElementStyle", {});
GlobalScope:Set("ElementList", {});
GlobalScope:Set("CurrentListItem", WindowDataItem);


ListItemMap[WindowDataItem.id] = WindowDataItem;

local function SetCurrentElement(curElement)
    CurrentElement = curElement;
    local CurrentElementId = CurrentElement and CurrentElement:GetAttrNumberValue("id");
    GlobalScope:Set("CurrentElementId", CurrentElementId);
    GlobalScope:Set("CurrentElementStyle", CurrentElement and CurrentElement:GetComputedStyle() or {});
    GlobalScope:Set("CurrentListItem", ListItemMap[CurrentElementId]);
end

local function RegisterElementEvent(el)
    -- el:SetAttrValue("onmousedown", )
end

function GetCurrentElementId()
    return GlobalScope:Get("CurrentElementId");
end

function DraggableElementOnMouseDown(el)
end

function DraggableElementOnMouseMove(el)
end

function DraggableElementOnMouseUp(el)
    GetEvent():accept();
    SetCurrentElement(el);
end

function OnReady()
    WindowElement = GetRef("window");
    SetCurrentElement(WindowElement);
    ClickNewElementBtn();
end


function GetListItemById(id)
    local list = GlobalScope:Get("ElementList");
    for i = 1, #list do 
        if (list[i].id == id) then 
            return list[i], i;
        end
    end
    return WindowDataItem, 0;
end

function ClickNewElementBtn()
    local list = GlobalScope:Get("ElementList");
    ElementId = ElementId + 1;
    local listitem = {text = "元素", id = ElementId};
    table.insert(list, listitem);
    ListItemMap[listitem.id] = listitem;
end

function ClickDeleteElementBtn()
    local CurrentElementId = GetCurrentElementId()
    if (not CurrentElementId) then return end
    local _, index = GetListItemById(CurrentElementId);
    if (index > 0) then 
        table.remove(GlobalScope:Get("ElementList"), index);
        ListItemMap[CurrentElementId] = nil;
    end
end

function ClickGenerateCodeBtn()
    local str = "";
    local function generateElementCode(el, data)
        local style = el:GetComputedStyle();
        local styleStr = "";
        for _, styleName in ipairs(StyleNameList) do 
            if (style[styleName]) then
                styleStr = string.format("%s:%s;%s", styleName, style[styleName], styleStr);
            end
        end
        local tagname = el:GetTagName();
        return string.format([[<%s style="%s">%s</%s>]], tagname, styleStr, data.text, tagname)
    end
    for _, childElement in ipairs(WindowElement.childrens) do
        local listitem, index = GetListItemById(childElement:GetAttrNumberValue("id"));
        if (index > 0) then
            str = str .. "\n\t" .. generateElementCode(childElement, listitem);
        end
    end
    str = string.format("<template>%s\n</template>", str);
    ParaMisc.CopyTextToClipboard(str);
    print(str);
    return str;
end