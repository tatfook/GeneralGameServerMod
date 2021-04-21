
local BlockToolbox = NPL.export();

local AllBlockList = {
    {
        type = "set_block_type",
        message = "图块-类型 %1",
        arg = {
            {
                name = "block_type",
                type = "field_input",
                text = "block"
            },
        },
        category = "BlockAttr",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local block_type = block:GetValueAsString("block_type");
            return string.format('type = "%s";\n', block_type);
        end,
    },
    {
        type = "set_block_category",
        message = "图块-类别 %1",
        arg = {
            {
                name = "block_category",
                type = "field_input",
                text = "category"
            },
        },
        category = "BlockAttr",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local block_category = block:GetValueAsString("block_category");
            return string.format('category = "%s";\n', block_category);
        end,
    },
    {
        type = "set_block_color",
        message = "图块-颜色 %1",
        arg = {
            {
                name = "block_color",
                type = "field_input",
                text = "#2E9BEF"
            },
        },
        category = "BlockAttr",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local block_color = block:GetValueAsString("block_color");
            return string.format('color = "%s";\n', block_color);
        end,
    },
    {
        type = "set_block_connection",
        message = "图块-连接 %1",
        arg = {
            {
                name = "block_connection",
                type = "field_dropdown",
                text = "StatementConnection",
                options = {
                    {"语句链接", "StatementConnection"},
                    {"值连接", "OutputConnection"},
                }
            },
        },
        category = "BlockAttr",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local block_connection = block:GetFieldValue("block_connection");
            if (block_connection == "OutputConnection") then
                return "previousStatement = false;\nnextStatement = false;\noutput = true;\n"
            else 
                return "previousStatement = true;\nnextStatement = true;\noutput = false;\n"
            end
        end,
    },
    {
        type = "set_field_text",
        message = "字段-文本 %1",
        arg = {
            {
                name = "field_text",
                type = "field_input",
                text = "文本内容",
            },
        },
        category = "BlockField",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local field_text = block:GetFieldValue("field_text");
            return string.format('message = message .. " " .. "%s";\n', field_text);
        end,
    },
    {
        type = "set_field_input",
        message = "字段-输入 %1 %2 %3",
        arg = {
            {
                name = "field_name",
                type = "field_input",
                text = "字段名",
            },
            {
                name = "field_value",
                type = "field_input",
                text = "默认值",
            },
            {
                name = "field_type",
                type = "field_dropdown",
                text = "field_input",
                options = {
                    {"文本", "field_input"},
                    {"数字", "field_number"},
                }
            },
        },
        category = "BlockField",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local field_name = block:GetFieldValue("field_name");
            local field_type = block:GetFieldValue("field_type");
            local field_value = block:GetFieldValue("field_value");
            return string.format('field_count = field_count + 1;\nmessage = message .. " %%" .. field_count;\narg[field_count] = {name = "%s", type = "%s", text = "%s"};\n', field_name, field_type, field_value);
        end,
    },

    {
        type = "set_field_dropdown",
        message = "字段-列表 %1 %2 %3",
        arg = {
            {
                name = "field_name",
                type = "field_input",
                text = "字段名",
            },
            {
                name = "field_value",
                type = "field_input",
                text = "默认值",
            },
            {
                name = "field_options",
                type = "input_statement",
                check = {"set_field_dropdown_option"},
            },
        },
        category = "BlockField",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local field_name = block:GetFieldValue("field_name");
            local field_value = block:GetFieldValue("field_value");
            local field_options = block:GetValueAsString("field_options");
            return string.format('field_count = field_count + 1;\nmessage = message .. " %%" .. field_count;\narg[field_count] = {name = "%s", type = "field_dropdown", text = "%s", options = {}};\nlocal field_dropdown_options = arg[field_count].options;\n%s', field_name, field_value, field_options);
        end,
    },

    {
        type = "set_field_dropdown_option",
        message = "字段-列表项 %1 %2",
        arg = {
            {
                name = "field_option_label",
                type = "field_input",
                text = "标签",
            },
            {
                name = "field_option_value",
                type = "field_input",
                text = "值",
            },
        },
        category = "BlockField",
        previousStatement = {"set_field_dropdown", "set_field_dropdown_option"},
	    nextStatement = {"set_field_dropdown_option"},
        ToNPL = function(block)
            local field_option_label = block:GetFieldValue("field_option_label");
            local field_option_value = block:GetFieldValue("field_option_value");
            return string.format('field_dropdown_options[#field_dropdown_options + 1] = {"%s", "%s"};\n', field_option_label, field_option_value);
        end,
    },

    {
        type = "set_input_value",
        message = "输入-值 %1 %2",
        arg = {
            {
                name = "input_name",
                type = "field_input",
                text = "名称",
            },
            {
                name = "input_value",
                type = "field_input",
                text = "默认值",
            },
        },
        category = "BlockInput",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local input_name = block:GetFieldValue("input_name");
            local input_value = block:GetFieldValue("input_value");
            return string.format('field_count = field_count + 1;\nmessage = message .. " %%" .. field_count;\narg[field_count] = {name = "%s", type = "input_value", text = "%s"};\n', input_name, input_value);
        end,
    },

    {
        type = "set_input_statement",
        message = "输入-语句 %1 %2",
        arg = {
            {
                name = "input_name",
                type = "field_input",
                text = "名称",
            },
        },
        category = "BlockInput",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local input_name = block:GetFieldValue("input_name");
            return string.format('field_count = field_count + 1;\nmessage = message .. " %%" .. field_count;\narg[field_count] = {name = "%s", type = "input_statement"};\n', input_name);
        end,
    },

    {
        type = "set_code_description",
        message = "代码-格式 %1",
        arg = {
            {
                name = "code_description",
                type = "field_textarea",
                text = "$FieldName",
            },
        },
        category = "BlockCode",
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local code_description = block:GetFieldValue("code_description");
            return string.format('code_description = [[%s]];\n', code_description);
        end,
    },
};

local AllBlockMap = {};

local AllCategoryList = {
    {
        name = "BlockAttr",
        text = "属性",
        color = "#2E9BEF",
        blocktypes = {}
    },
    {
        name = "BlockField",
        text = "字段",
        color = "#76CE62",
        blocktypes = {}
    },
    {
        name = "BlockInput",
        text = "输入",
        color = "#764BCC",
        blocktypes = {}
    },
    {
        name = "BlockCode",
        text = "代码",
        color = "#EC522E",
        blocktypes = {}
    },
}
local AllCategoryMap = {};

for _, category in ipairs(AllCategoryList) do
    AllCategoryMap[category.name] = category;
end

for _, block in ipairs(AllBlockList) do
    AllBlockMap[block.type] = block;
    local category = block.category and AllCategoryMap[block.category];
    if (category) then
        block.color = category.color;
        table.insert(category.blocktypes, #(category.blocktypes) + 1, block.type);
    end
end

function BlockToolbox.GetAllBlocks()
    return AllBlockList, AllBlockMap;
end

function BlockToolbox.GetCategoryList()
    return AllCategoryList, AllCategoryMap;
end
