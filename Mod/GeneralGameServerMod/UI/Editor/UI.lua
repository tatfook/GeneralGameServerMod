
local GlobalScope = GetGlobalScope();

_G.WindowElement = nil;
_G.BlocklyElement = nil;
_G.CurrentElement = nil;
_G.CurrentListItemData = {};
_G.ListItemDataMap = {};

_G.StyleNameList = {
    "width", "height", "left", "top", "right", "bottom", "display", "position", "font-size", "color", "background", "background-color",
    "margin-top", "margin-right", "margin-bottom", "margin-left", "padding-top", "padding-right", "padding-bottom", "padding-left", 
};

local function GetStyleString(style)
    local styleString = "";
    for _, styleName in ipairs(StyleNameList) do 
        if (style[styleName]) then
            styleString = string.format("%s:%s;%s", styleName, style[styleName], styleString);
        end
    end
    return styleString;
end

local ElementId = 0;
local function GetNextElementId()
    ElementId = ElementId + 1;
    return string.format("ID_%s", ElementId);
end

local function GenerateListItemData(opt)
    local item = {
        id = GetNextElementId(),
        text = "",
        textVarName = "",  -- 动态文本
        style = { 
            width = 200,
            height = 100,
        },
        hoverStyle = {},
        attr = {},
        vbind = {},
    }

    commonlib.partialcopy(item, opt);

    return item;
end

_G.CurrentElementStyleChange = function ()

end

_G.WindowDataItem = GenerateListItemData({style = {width = "100%", height = "100%"}});

GlobalScope:Set("CurrentElementId", "");
GlobalScope:Set("ElementList", {});
GlobalScope:Set("AllCode", "");

ListItemDataMap[WindowDataItem.id] = WindowDataItem;

local function SetCurrentElement(curElement)
    _G.CurrentElement = curElement;
    local CurrentElementId = CurrentElement and CurrentElement:GetAttrStringValue("id");

    _G.CurrentListItemData = ListItemDataMap[CurrentElementId];
    GlobalScope:Set("CurrentElementId", CurrentElementId);
end

function GetCurrentElementId()
    return GlobalScope:Get("CurrentElementId");
end

function DraggableFlagElementOnMouseDown(el)
    el:GetParentElement():OnMouseDown(GetEvent());
end

function DraggableFlagElementOnMouseMove(el)
    el:GetParentElement():OnMouseMove(GetEvent());
end

function DraggableFlagElementOnMouseUp(el)
    el:GetParentElement():OnMouseUp(GetEvent());
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
    _G.WindowElement = GetRef("window");
    _G.BlocklyElement = GetRef("blockly");
    SetCurrentElement(_G.WindowElement);
    ClickNewElementBtn();
end


_G.GetListItemById = function(id)
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
    local item = GenerateListItemData({
        style = {
            position = "absolute",
            left = 0,
            top = 0,
        }
    });
    _G.ListItemDataMap[item.id] = item;
    table.insert(list, {id = item.id, text = item.text});
end

function ClickDeleteElementBtn()
    local CurrentElementId = GetCurrentElementId()
    if (not CurrentElementId) then return end
    local _, index = GetListItemById(CurrentElementId);
    if (index > 0) then 
        table.remove(GlobalScope:Get("ElementList"), index);
        _G.ListItemDataMap[CurrentElementId] = nil;
    end
end

_G.GenerateCode = function()
    local allcode = "";
    -- local IdSuffix = os.time();
    -- template
    local function generateElementCode(el, item)
        if (not item) then return "" end
        local tagname = item.tagname or el:GetTagName();
        local left, top = el:GetPosition();
        item.style.left = left .. "px";
        item.style.top = top .. "px";
        local attrString = "";
        for key, val in pairs(item.attr) do attrString = string.format('%s="%s" %s', key, val, attrString) end
        local vbindAttrString = "";
        for key, val in pairs(item.vbind) do vbindAttrString = string.format('v-bind:%s="%s" %s', key, val, vbindAttrString) end
        local textString = "";
        
        if (item.text ~= "") then textString = item.text end
        if (item.textVarName ~= "") then textString = "{{" .. item.textVarName .. "}}" end

        -- local idString = string.format("%s_%s", item.id, IdSuffix);
        -- return string.format([[<%s id="%s" %s %s style="%s">%s</%s>]], tagname, idString, vbindAttrString, attrString, GetStyleString(item.style), item.text, tagname)
        return string.format([[<%s %s %s style="%s">%s</%s>]], tagname, vbindAttrString, attrString, GetStyleString(item.style), item.text, tagname)
    end

    for _, childElement in ipairs(WindowElement.childrens) do
        local id = childElement:GetAttrStringValue("id", "");
        local listitem = _G.ListItemDataMap[id];
        if (listitem) then allcode = allcode .. "\n\t" .. generateElementCode(childElement, listitem) end
    end

    -- allcode = string.format('<template id="%s_%s" style="%s">%s\n</template>', WindowDataItem.id, IdSuffix, GetStyleString(WindowDataItem), allcode);
    allcode = string.format('<template style="%s">%s\n</template>', GetStyleString(WindowDataItem.style), allcode);
    ParaMisc.CopyTextToClipboard(allcode);

    -- script
    local rawcode, prettycode = BlocklyElement:GetCode();
    allcode = allcode .. '\n<script type="text/lua">\n' .. prettycode .. '</script>\n';
    GlobalScope:Set("AllCode", allcode);

    print(allcode);
    return allcode;
end

