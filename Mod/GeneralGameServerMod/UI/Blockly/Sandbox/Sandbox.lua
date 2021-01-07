--[[
Title: Sandbox
Author(s): wxa
Date: 2020/6/30
Desc: npl 代码执行环境
use the lib:
-------------------------------------------------------
local Sandbox = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Sandbox/Sandbox.lua");
-------------------------------------------------------
]]

local Global = NPL.load("./Global.lua", IsDevEnv);

local Sandbox = NPL.export();

function Sandbox.GetG()
    return Global;
end

function Sandbox.ExecCode(code)
    -- 清空输出缓存区
    Global.ClearOut();

    if (type(code) ~= "string" or code == "") then return Global.GetOut() end
    local func, errmsg = loadstring(code);
    if (not func) then 
        print("===============================Exec Code Error=================================", errmsg) 
        return Global.GetOut();
    end

    setfenv(func, Sandbox.GetG());

    xpcall(function()
        func();
    end, function(errinfo) 
        print("ERROR:", errinfo)
        DebugStack();
    end);

    return Global.GetOut();
end
