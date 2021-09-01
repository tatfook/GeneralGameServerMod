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
};

local all_cmds = {
};

function GIBlockly.GetCategoryButtons()
	return categories;
end

function GIBlockly.GetAllCmds()
	return all_cmds;
end

function GIBlockly.CompileCode(code, filename, codeblock)
    local __env__ = GameLogic.GetCodeGlobal():GetGI():GetSandboxAPI().__get_module_env__();
    __env__.__codeblock__ = codeblock;
    __env__.__codeblock_env__ = codeblock:GetCodeEnv();
    __env__.__module__.__filename__ = filename;
    __env__.__codeblock_env__.__checkyield__ = function() end 
    __env__.__codeblock_env__.__fileline__ = function() end 
    
    code = __env__.__inject_checkyield_to_code__(code);
    local code_func, errormsg = loadstring(code, filename);
    if(not code_func or errormsg) then
        LOG.std(nil, "error", "CodeBlock", errormsg);
        print("================ GIBlockly.CompileCode ===============", code);
        return ;
    end

    setfenv(code_func, __env__);

    -- 环境重新加载
    local __rawset__ = rawset;
    local __setfenv__ = setfenv;
    local format = string.format;
    return function() 
        if (not __env__.__is_running__()) then __env__.__restart__() end
        local __cur_co__ = __env__.__coroutine_running__();
        __rawset__(__env__, "runInGIEnv", function(callback)
            if (type(callback) ~= "function") then return end 
            __setfenv__(callback, __env__);
            callback();
        end);
        __rawset__(__env__, "runInCodeBlockEnv", function(callback)
            if (type(callback) ~= "function") then return end 
            __setfenv__(callback, __env__.__codeblock_env__);
            callback();
        end);
        __rawset__(__env__, "registerStopEvent", function(callback)
            __env__.RegisterEventCallBack(format("__code_block_stop__%s", __cur_co__), callback);
        end);
        __rawset__(__env__, "registerCodeBlockStopEvent", __env__.registerStopEvent);
        
        __env__.__module__.__reload__ = function()
            __env__.__module__.__run_co__ = __env__.__independent_run__(code_func);
        end
        __env__.__module__.__reload__();
        registerStopEvent(function()
            __env__.TriggerEventCallBack(format("__code_block_stop__%s", __cur_co__));
            __env__.__module__.__reload__ = nil;
            __env__.__coroutine_exit_all__(__env__.__module__.__run_co__, true);
            __env__.__module__.__run_co__ = nil;
        end);
    end
end