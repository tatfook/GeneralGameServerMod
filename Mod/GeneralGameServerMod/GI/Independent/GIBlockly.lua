--[[
Title: BlocklyConfig
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local GIBlockly = NPL.load("Mod/GeneralGameServerMod/GI/Independent/GIBlockly.lua");
------------------------------------------------------------
]]

local GIBlockly = NPL.export();

local categories = {
    {name = "Look", text = "外观", colour = "#2E9BEF", },
    {name = "Control", text = "控制", colour = "#76CE62", },
};

local all_cmds = {
    -- 外观
    {
        type = "SetCamera", 
        message = "摄影机 距离 %1 角度 %2 朝向 %3",
        arg = {
            {
                name = "dist",
                type = "input_value",
                shadowType = "field_number",
                text = "12", 
            },
            {
                name = "pitch",
                type = "input_value",
                shadowType = "field_number",
                text = "45", 
            },
            {
                name = "facing",
                type = "input_value",
                shadowType = "field_number",
                text = "90", 
            },
        },
        category = "Look", 
        previousStatement = true,
        nextStatement = true,
        code_description = "SetCamera(${dist}, ${pitch}, ${facing});\n",
    },

    {
        type = "SetCameraLookAtBlockPos", 
        message = "摄影机聚焦位置 X %1 Y %2 Z %3",
        arg = {
            {
                name = "x",
                type = "input_value",
                shadowType = "field_number",
                text = "20000", 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "field_number",
                text = "4", 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "field_number",
                text = "20000", 
            },
        },
        category = "Look", 
        previousStatement = true,
        nextStatement = true,
        code_description = "SetCameraLookAtBlockPos(${x}, ${y}, ${z});\n",
    },

    -- 控制
    -- {
    --     type = "SetCameraLookAtBlockPos", 
    --     message = "摄影机聚焦位置 X %1 Y %2 Z %3",
    --     arg = {
    --         {
    --             name = "x",
    --             type = "input_value",
    --             shadowType = "field_number",
    --             text = "20000", 
    --         },
    --         {
    --             name = "y",
    --             type = "input_value",
    --             shadowType = "field_number",
    --             text = "4", 
    --         },
    --         {
    --             name = "z",
    --             type = "input_value",
    --             shadowType = "field_number",
    --             text = "20000", 
    --         },
    --     },
    --     category = "Look", 
    --     previousStatement = true,
    --     nextStatement = true,
    --     code_description = "SetCameraLookAtBlockPos(${x}, ${y}, ${z});\n",
    -- },
};

function GIBlockly.GetCategoryButtons()
	return categories;
end

function GIBlockly.GetAllCmds()
	return all_cmds;
end

function GIBlockly.CompileCode(code, filename, codeblock)
    local code_func, errormsg = loadstring(code, filename);
    if(not code_func or errormsg) then
        LOG.std(nil, "error", "CodeBlock", self.errormsg);
        return ;
    end

    local __codeblock_env__ = codeblock:GetCodeEnv();
    local api = GameLogic.GetCodeGlobal():GetSandboxAPI().API;
    local G = setmetatable({__codeblock__ = codeblock, __codeblock_env__ = __codeblock_env__}, {__index = api});
    
    setfenv(code_func, G);
    
    return function() 
        code_func();
    end
end