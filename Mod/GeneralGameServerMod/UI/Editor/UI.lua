
local GlobalScope = GetGlobalScope();

local WindowElement = nil;

_G.StyleNameList = {
    "width", "height", "left", "top", "right", "bottom", "display", "position", "font-size", "color", "background", "background-color",
    "margin-top", "margin-right", "margin-bottom", "margin-left", "padding-top", "padding-right", "padding-bottom", "padding-left", 
};

local ElementId = 0;

GlobalScope:Set("CurrentElement", nil);
GlobalScope:Set("CurrentElementStyle", {});
GlobalScope:Set("ElementList", {});


local function SetCurrentElement(CurrentElement)
    GlobalScope:Set("CurrentElement", CurrentElement);
    GlobalScope:Set("CurrentElementStyle", CurrentElement and CurrentElement:GetComputedStyle() or {});
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

end


function ClickNewElementBtn()
    local list = GlobalScope:Get("ElementList");
    ElementId = ElementId + 1;
    table.insert(list, {text = "元素", id = ElementId});
end

function ClickDeleteElementBtn()
end

