
local GlobalScope = GetGlobalScope();

local WindowElement = nil;

_G.StyleNameList = {
    "width", "height", "left", "top", "right", "bottom", "display", "position", "font-size", "color", "background", "background-color",
    "margin-top", "margin-right", "margin-bottom", "margin-left", "padding-top", "padding-right", "padding-bottom", "padding-left", 
};

local ElementId = 0;

WindowDataItem = {id = 0, text = ""};
GlobalScope:Set("CurrentElement", nil);
GlobalScope:Set("CurrentElementStyle", {});
GlobalScope:Set("ElementList", {});
GlobalScope:Set("CurrentListItem", WindowDataItem);

local function SetCurrentElement(curElement)
    GlobalScope:Set("CurrentElement", curElement);
    GlobalScope:Set("CurrentElementStyle", curElement and curElement:GetComputedStyle() or {});
    local listitem = GetListItemById(curElement:GetAttrNumberValue("id"));
    GlobalScope:Set("CurrentListItem", listitem);
end

local function RegisterElementEvent(el)
    -- el:SetAttrValue("onmousedown", )
end

function DraggableElementOnMouseDown(el)
end

function DraggableElementOnMouseMove(el)
end

function DraggableElementOnMouseUp(el)
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
    table.insert(list, {text = "元素", id = ElementId});
end

function ClickDeleteElementBtn()
    local el = GlobalScope:Get("CurrentElement");
    if (not el or el == WindowElement) then return end
    local _, index = GetListItemById(el:GetAttrNumberValue("id"));
    if (index > 0) then table.remove(GlobalScope:Get("ElementList"), index) end
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