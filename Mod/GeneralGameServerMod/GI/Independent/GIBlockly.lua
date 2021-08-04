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

local categories = {};

local all_cmds = {};

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