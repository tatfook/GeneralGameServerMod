

local BlockManager = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Blocks/BlockManager.lua");
local Helper = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Helper.lua");

BlockManager.SetCurrentLanguage(_G.Language);

ContentType = "xmltext"; -- block category
ToolBoxXmlText = _G.XmlText or BlockManager.GenerateToolBoxXmlText();
ToolBoxBlockList = {};
ToolBoxCategoryList = {};

local AllCategoryList = {};
local function GetToolBoxBlockList()
    local blocklist = {};
    for _, category in ipairs(AllCategoryList) do
        for index, block in ipairs(category) do 
            table.insert(blocklist, {blockType = block.blocktype, categoryName = category.name, hideInToolbox = block.hideInToolbox, order = index, index = index});
        end
    end
    return blocklist;
end

local function GetToolBoxCategoryList()
    local categories = {};
    for index, category in ipairs(AllCategoryList) do
        table.insert(categories, {name = category.name, color = category.color, hideInToolbox = category.hideInToolbox, index = index, order = index, blockCount = category.blockCount});
    end
    return categories;
end

local function ParseToolBoxXmlText()
    local xmlNode = ParaXML.LuaXML_ParseString(ToolBoxXmlText);
    local toolboxNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//toolbox");
    local categorylist, categorymap = {}, {};

    if (not toolboxNode) then return {} end
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(path);
    local AllCategoryMap, AllBlockMap = CategoryAndBlockMap.AllCategoryMap, CategoryAndBlockMap.AllBlockMap;

    for _, categoryNode in ipairs(toolboxNode) do
        if (categoryNode.attr and categoryNode.attr.name) then
            local category_attr = categoryNode.attr;
            local default_category = AllCategoryMap[category_attr.name] or {};
            local category = categorymap[category_attr.name] or {};
            category.name = category.name or category_attr.name or default_category.name;
            category.text = category.text or category_attr.text or default_category.text;
            category.color = category.color or category_attr.color or default_category.color;
            local hideInToolbox = if_else(category_attr.hideInToolbox ~= nil, category_attr.hideInToolbox == "true", default_category.hideInToolbox and true or false);
            category.hideInToolbox = if_else(category.hideInToolbox ~= nil, category.hideInToolbox, hideInToolbox);
            if (not categorymap[category.name]) then
                table.insert(categorylist, #categorylist + 1, category);
                categorymap[category.name] = category;
            end            
            for _, blockTypeNode in ipairs(categoryNode) do
                if (blockTypeNode.attr and blockTypeNode.attr.type) then
                    local blocktype = blockTypeNode.attr.type;
                    local hideInToolbox = blockTypeNode.attr.hideInToolbox == "true";
                    if (AllBlockMap[blocktype]) then
                        table.insert(category, {blocktype = blocktype, hideInToolbox = hideInToolbox});
                    end
                end
            end
        end
    end

    return categorylist;
end

local function GenerateToolBoxXmlText()
    local toolbox = {name = "toolbox"};
    for _, categoryItem in ipairs(AllCategoryList) do
        local category = {
            name = "category",
            attr = {name = categoryItem.name, color = categoryItem.color, text = categoryItem.text, hideInToolbox = categoryItem.hideInToolbox and "true" or nil},
        }
        table.insert(toolbox, #toolbox + 1, category);
        for _, blockItem in ipairs(categoryItem) do 
            table.insert(category, #category + 1, {name = "block", attr = {type = blockItem.blocktype, hideInToolbox = blockItem.hideInToolbox and "true" or nil}});
        end
    end
    local xmlText = Helper.Lua2XmlString(toolbox, true);
    return xmlText;
end

function OnToolBoxCategoryOrderChange(category)
    category.order = tonumber(category.order) or category.index;
    category.order = math.max(1, math.min(#ToolBoxCategoryList, category.order));
    if (category.order == category.index) then return end
    local order, index = category.order, category.index;
    ToolBoxCategoryList[order].order, ToolBoxCategoryList[order].index = index, index; 
    ToolBoxCategoryList[index].order, ToolBoxCategoryList[index].index = order, order; 
    ToolBoxCategoryList[order], ToolBoxCategoryList[index] = ToolBoxCategoryList[index], ToolBoxCategoryList[order];
    -- AllCategoryList[order], AllCategoryList[index] = AllCategoryList[index], AllCategoryList[order];
end

function SwitchToolBoxCategoryVisible(category)
    category.hideInToolbox = not category.hideInToolbox;
end

function OnToolBoxBlockOrderChange(block)
    block.order = tonumber(block.order) or block.index;
    block.order = math.max(1, math.min(#ToolBoxBlockList, block.order));
    if (block.order == block.index) then return end
    local order, index = block.order, block.index;
    ToolBoxBlockList[order].order, ToolBoxBlockList[order].index = index, index; 
    ToolBoxBlockList[index].order, ToolBoxBlockList[index].index = order, order; 
    ToolBoxBlockList[order], ToolBoxBlockList[index] = ToolBoxBlockList[index], ToolBoxBlockList[order];
end

function SwitchToolBoxBlockVisible(block)
end

function OnReady()
end

function SetContentType(contentType)
    if (ContentType == "xmltext" and contentType ~= "xmltext") then
        AllCategoryList = ParseToolBoxXmlText();
        ToolBoxBlockList = GetToolBoxBlockList();
        ToolBoxCategoryList = GetToolBoxCategoryList();
    end
    if (ContentType ~= "xmltext" and contentType == "xmltext") then
        ToolBoxXmlText = GenerateToolBoxXmlText();
    end
    ContentType = contentType;
end

function GetHeaderBtnStyle(contentType)
    if (ContentType == contentType) then return "border-bottom: 1px solid #ffffff" end
    return "";
end

function GetCategoryColorStyle(category)
    return string.format([[width: 20px; height: 20px; background-color: %s; border-radius: 10px; margin-top: 4px; margin-left: 8px;]], (not category.color or category.color == "") and "#ffffff" or category.color);
end

function ClickConfirm()
end
