

local BlockManager = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Blocks/BlockManager.lua");
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
local Blockly = nil;
local BlocklyEditor = nil;
local BlocklyPreview = nil;
local BlockOption = {};
LangOptions = {{"定制世界图块", "CustomWorldBlock"}, {"系统 NPL 图块", "SystemNplBlock"}, {"系统 Lua 图块", "SystemLuaBlock"}};
CurrentLang = "CustomWorldBlock";
TabIndex = "block";
ContentType = "block"; -- block blockly
BlocklyCode = "";
BlockType = "";
BlockDefineCode = "";
ToolBoxXmlText = "";
AllCategoryList, AllBlockList = {}, {};
Category = {name = "", color = "#ffffff"};
SearchCategoryOptions = {{"全部", ""}};
SearchCategoryName = "";
SearchBlockType = "";
function SelectSearchCategory()
    OnChange();
end

function OnSearchBlockTypeChange(value)
    SearchBlockType = value;
    OnChange();
end

function OnSelectLang()
    BlockManager.SetCurrentLanguage(CurrentLang);
    OnChange();
end

function ClickUpdateToolBoxXmlText()
    BlockManager.ParseToolBoxXmlText(ToolBoxXmlText);
    ToolBoxXmlText = BlockManager.GetToolBoxXmlText();
    GameLogic.AddBBS("Blockly", "工具栏更新成功");
end 

function ClickTabNavItemBtn(tabindex)
    TabIndex = tabindex;
    OnChange();
end 

function GetTabNavItemStyle(tabindex)
    return TabIndex == tabindex and "color: #ffffff;" or "";
end

function GetCategoryColorStyle(category)
    return string.format([[width: 20px; height: 20px; background-color: %s; border-radius: 10px; padding: 0px 10px;]], category.color);
end

function ClickEditCategoryBtn()
    if (Category.name == "") then return end
    local AllCategoryMap = BlockManager.GetLanguageCategoryMap();
    AllCategoryMap[Category.name] = AllCategoryMap[Category.name] or {name = Category.name, color = Category.color};    
    local isExist = false;
    for _, category in ipairs(AllCategoryList) do 
        if (category.name == Category.name) then 
            category.color = Category.color or category.color; 
            isExist = true;
            break;
        end 
    end
    if (not isExist) then table.insert(AllCategoryList, {name = Category.name, color = Category.color}) end 
    OnToolBoxXmlTextChange();
end

function ClickDeleteCategoryBtn(categoryName)
    local AllCategoryMap = BlockManager.GetLanguageCategoryMap();
    AllCategoryMap[categoryName] = nil;
    for i, category in ipairs(AllCategoryList) do 
        if (category.name == categoryName) then
            table.remove(AllCategoryList, i);
        end
    end
    BlockManager.SaveCategoryAndBlock();
    OnToolBoxXmlTextChange();
end


function SetContentType(contentType)
    ContentType = contentType;
    if (ContentType == "blockly" and Blockly) then
        Blockly:OnAttrValueChange("type", "custom");
    end
end

function GetHeaderBtnStyle(contentType)
    if (ContentType == contentType) then return "border-bottom: 1px solid #ffffff" end
    return "";
end

local function EditBlock(blockType)
    if (BlockType == blockType) then return end
    BlockType = blockType;
    local AllBlockMap = BlockManager.GetLanguageBlockMap();
    LoadBlockXmlText(AllBlockMap[BlockType]);
    OnBlocklyEditorChange();
end 

function SelectBlock(blockType)
    EditBlock(blockType);
end 

function ClickSaveBlockBtn()
    BlockOption.xml_text = BlocklyEditor:SaveToXmlNodeText();
    if (BlockType == "") then return end
    local isExist = false;
    for i, opt in ipairs(AllBlockList) do
        if (opt.type == BlockType) then
            isExist = true;
            break;
        end
    end 
    if (not isExist) then
        table.insert(AllBlockList, {type = BlockOption.type, category = BlockOption.category});
    end

    BlockManager.NewBlock(BlockOption);
    GameLogic.AddBBS("Blockly", "图块更改已保存");
    OnToolBoxXmlTextChange();
end

function ClickDeleteBlockBtn(blocktype)
    blocktype = blocktype or BlockType;
    if (blocktype == "") then return end
    for i, block in ipairs(AllBlockList) do 
        if (block.type == blocktype) then
            table.remove(AllBlockList, i);
            break;
        end
    end
    BlockManager.DeleteBlock(blocktype);
    BlockType = "";
    BlocklyEditor:Reset();
    OnBlocklyEditorChange();
    OnToolBoxXmlTextChange();
end

function ClickEditBlockBtn(blockType)
    EditBlock(blockType);
end

function LoadBlockXmlText(block)
    if (not block or not block.xml_text) then return end
    BlocklyEditor:LoadFromXmlNodeText(block.xml_text);
end

function GenerateBlockOption()
    local rawcode, prettycode = BlocklyEditor:GetCode();
    local prettycode = string.gsub(prettycode, "\t", "    ");
    local G = {message = "", arg = {}, field_count = 0, type="", category = "图块", color = "#2E9BEF", output = false, previousStatement = true, nextStatement = true, connections = {}};
    local func, errmsg = loadstring(prettycode);
    if (not func) then
        print("============================loadstring error==========================", errmsg);
        print(prettycode)
        return nil;
    end
    setfenv(func, G);
    local isError = false;
    xpcall(function()
        func();
    end, function(errinfo) 
        print("ERROR:", errinfo);
        DebugStack();
        isError = true;
    end);
    if (isError) then return nil end 

    G.message = string.gsub(G.message, "^ ", "");
    
    local connections = G.connections;
    G.connections = nil;
    if (connections.output and connections.output ~= "") then G.output = connections.output end
    if (connections.previousStatement and connections.previousStatement ~= "") then G.previousStatement = connections.previousStatement end
    if (connections.nextStatement and connections.nextStatement ~= "") then G.nextStatement = connections.nextStatement end
    for _, arg in ipairs(G.arg) do
        if (arg.type == "input_value" or arg.type == "input_statement") then
            local argname = arg.name;
            if (connections[argname] and connections[argname] ~= "") then 
                arg.check = connections[argname];
            end
        end
    end 

    return G;
end

function PreviewBlockOption(blockOption)
    BlocklyPreview:DefineBlock(blockOption);
    local block = BlocklyPreview:GetBlockInstanceByType(blockOption.type);
    BlocklyPreview:ClearBlocks();
    block:SetLeftTopUnitCount(10, 10);
    block:UpdateLayout();
    BlocklyPreview:AddBlock(block);
end

function OnBlocklyEditorChange()
    local option = GenerateBlockOption();
    if (not option) then return end
    BlockOption = option;
    PreviewBlockOption(BlockOption);
    OnBlockDefineCodeChange();

    local AllBlockMap = BlockManager.GetLanguageBlockMap();
    if (BlockOption.type ~= BlockType) then
        BlockType = BlockOption.type;
        if (AllBlockMap[BlockOption.type]) then
            Page.ShowMessageBoxPage({
                text = string.format("图块 %s 已经存在, 是否加载已有信息?", BlockOption.type),
                confirm = function()
                    LoadBlockXmlText(AllBlockMap[BlockOption.type]);
                end,
            });
        end
    end
end

function OnBlocklyChange()
    if (not Blockly) then return end
    local rawcode, prettycode = Blockly:GetCode();
    BlocklyCode = string.gsub(prettycode, "\t", "    ");
end


function OnToolBoxXmlTextChange()
    if (Blockly) then
        Blockly:OnAttrValueChange("language");
    end
    if (TabIndex ~= "toolbox" or ContentType ~= "block") then return end
    ToolBoxXmlText = BlockManager.GetToolBoxXmlText();
end

function GenerateBlockDefineCode(option)
    local indent = "        ";
    local arg_var_define = indent .. "local args = {};\n";

    for i, arg in ipairs(option.arg) do
        if (arg.type == "input_value" or arg.type == "input_value_list" or arg.type == "input_statement") then
            arg_var_define = arg_var_define .. string.format('%sargs["%s"] = block:GetValueAsString("%s");\n', indent, arg.name, arg.name);
        else
            arg_var_define = arg_var_define .. string.format('%sargs["%s"] = block:GetFieldValue("%s");\n', indent, arg.name, arg.name);
        end
    end 

    local code_description = option.code_description or "";
    code_description = string.gsub(code_description, "\n+$", "");
    code_description = string.gsub(code_description, "^\n+", "");
    if (option.output) then
        code_description = "[====[" .. code_description .. "]====]";
    else
        code_description = "[====[\n" .. code_description .. "\n]====]";
    end
    
    local func_description = string.gsub(code_description, "%$(%w+)", "%%s");
    local block_define_code = string.format([[
{
    type = "%s",
    category = "%s",
    color = "%s",
    output = %s,
    previousStatement = %s, 
    nextStatement = %s,
    message = "%s",
    %s,
    ToCode = function(block)
%s
        -- 更改下行为图块实际生成代码
        return string.gsub(%s, "%%$([%%w_]+)", args); 
    end
}]], option.type, option.category, option.color, option.output, option.previousStatement, option.nextStatement, option.message, 
    commonlib.dump(option.arg, "arg", false, 2), arg_var_define, code_description);

    return block_define_code;
end

function OnBlockDefineCodeChange()
    if (TabIndex ~= "code" or ContentType ~= "block") then return end
    BlockDefineCode = GenerateBlockDefineCode(BlockOption);
end

function OnChange()
    OnBlockListChange();
    OnCategoryListChange();
    OnToolBoxXmlTextChange();
    OnBlockDefineCodeChange();
end

function OnBlockListChange()
    if (TabIndex ~= "block" or ContentType ~= "block") then return end
    local AllBlockMap = BlockManager.GetLanguageBlockMap();
    local allBlockList = {};
    for _, block in pairs(AllBlockMap) do
        if (SearchCategoryName == "" or SearchCategoryName == block.category) then
            local blocktype = string.lower(block.type);
            if (SearchBlockType == "" or (string.find(blocktype, SearchBlockType, 1, true))) then
                table.insert(allBlockList, {type = block.type, category = block.category});
            end
        end
    end
    table.sort(allBlockList, function(block1, block2)
        return block1.category == block2.category and (block1.type < block2.type) or (block1.category < block2.category);
    end);
    AllBlockList = allBlockList;

    local AllCategoryMap = BlockManager.GetLanguageCategoryMap();
    SearchCategoryOptions = {{"全部", ""}};
    for _, category in pairs(AllCategoryMap) do
        table.insert(SearchCategoryOptions, {category.text or category.name, category.name});
    end
end

function OnCategoryListChange()
    if (TabIndex ~= "category" or ContentType ~= "block") then return end
    local AllCategoryMap = BlockManager.GetLanguageCategoryMap();
    AllCategoryList = {};
    for _, category in pairs(AllCategoryMap) do
        table.insert(AllCategoryList, {name = category.name, text = category.text, color = category.color or "#ffffff"});
    end
end

function OnReady()
    OnSelectLang();
    Blockly = GetRef("Blockly");
    BlocklyEditor = GetRef("BlocklyEditor");
    BlocklyPreview = GetRef("BlocklyPreview");
    OnBlocklyEditorChange();
end