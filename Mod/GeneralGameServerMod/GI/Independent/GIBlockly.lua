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
-- NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
-- local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
-- local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");

local GIBlockly = NPL.export();

local categories = {
    -- {name = "Look", text = "外观", colour = "#2E9BEF", },
    -- {name = "Control", text = "控制", colour = "#76CE62", },
};

local all_cmds = {
    -- 外观
    -- {
    --     type = "SetCamera", 
    --     message = "摄影机 距离 %1 角度 %2 朝向 %3",
    --     arg = {
    --         {
    --             name = "dist",
    --             type = "input_value",
    --             shadowType = "field_number",
    --             text = "12", 
    --         },
    --         {
    --             name = "pitch",
    --             type = "input_value",
    --             shadowType = "field_number",
    --             text = "45", 
    --         },
    --         {
    --             name = "facing",
    --             type = "input_value",
    --             shadowType = "field_number",
    --             text = "90", 
    --         },
    --     },
    --     category = "Look", 
    --     previousStatement = true,
    --     nextStatement = true,
    --     code_description = "SetCamera(${dist}, ${pitch}, ${facing});\n",
    -- },

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


local __all_env__ = {};


local function GetCodeEnv(codeblock)
    local bx, by, bz = codeblock:GetBlockPos();
    local key = string.format("%s_%s_%s", bx, by, bz);
    if (__all_env__[key]) then return __all_env__[key] end
    local __env__ = {};

    __env__.__codeblock__ = codeblock;
    __env__.__codeblock_env__ = codeblock:GetCodeEnv();
    __env__.__gi_env__ = GameLogic.GetCodeGlobal():GetSandboxAPI().API;
    setmetatable(__env__, {__index = __env__.__gi_env__});

    __all_env__[key] = __env__;

    return __env__;
end

function GIBlockly.CompileRun(code, filename, codeblock)
end

-- function GIBlockly.CompileCode(code, filename, codeblock)
--     local code_func, errormsg = loadstring(code, filename);
--     if(not code_func or errormsg) then
--         LOG.std(nil, "error", "CodeBlock", errormsg);
--         return ;
--     end

--     local __env__ = GetCodeEnv(codeblock);
--     setmetatable(__env__, {__index = __env__.__gi_env__})
--     setfenv(code_func, __env__);
    
--     --  TODO 重复执行需要提供回收机制
--     local IsDedug = CodeBlockWindow.IsVisible() and CodeBlockWindow.GetCodeBlock() == codeblock;
--     local viewport = ViewportManager:GetSceneViewport();
--     __env__.IsDevEnv = IsDevEnv;

--     return function() 
--         if (IsDedug) then
--             local SandBox = NPL.load("Mod/GeneralGameServerMod/GI/Independent/SandBox.lua", __env__.IsDevEnv);
--             local SandBoxClone = commonlib.inherit(SandBox, {});
--             SandBoxClone:InitSingleton();
--             __env__.__gi_env__ = SandBoxClone:GetAPI();
--             setmetatable(__env__, {__index = __env__.__gi_env__})
--         end

--         code_func();

--         if (IsDedug) then
--             registerStopEvent(function()
--                 __env__.__gi_env__.__stop__();
--                 if (CodeBlockWindow.IsVisible()) then
--                     viewport:SetMarginRight(CodeBlockWindow.margin_right);
--                 else
--                     viewport:SetMarginRight(0);
--                 end
--             end)
--         end
--     end
-- end

function GIBlockly.CompileCode(code, filename, codeblock)
    local code_func, errormsg = loadstring(code, filename);
    if(not code_func or errormsg) then
        LOG.std(nil, "error", "CodeBlock", errormsg);
        return ;
    end

    local __env__ = GetCodeEnv(codeblock);
    setfenv(code_func, __env__);
    
    return function() 
        local __cur_co__ = __env__.__gi_env__.__coroutine_running__();
        code_func();

        registerStopEvent(function()
            __env__.__gi_env__.__clean_coroutine_data__(__cur_co__);
        end)
    end
end