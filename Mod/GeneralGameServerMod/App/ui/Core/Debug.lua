--[[
Title: Debug
Author(s): wxa
Date: 2020/6/30
Desc: 调试类
use the lib:
-------------------------------------------------------
local Debug = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Debug.lua");
-------------------------------------------------------
]]

local Debug = NPL.export()

local ModuleLogEnableMap = {
    FATAL = true,
    ERROR = true,
    WARN = true,
    INFO = true,
    DEBUG = IsDevEnv and true or false,
}

local ModelDebug = {};

if (IsDevEnv) then 
    ModuleLogEnableMap["NET"] = false;
else

end

function Debug.IsEnableModule(module)
    module = string.upper(module or "DEBUG");
    return ModuleLogEnableMap[module];
end

function Debug.ToggleModule(module)
    module = string.upper(module or "DEBUG");
    ModuleLogEnableMap[module] = not ModuleLogEnableMap[module];
end

function Debug.EnableModule(module)
    ModuleLogEnableMap[module] = true;
end


local function DefaultOutput(...)
    ParaGlobal.WriteToLogFile(...);
    ParaGlobal.WriteToLogFile("\n");
end

local function Print(val, key, output, indent, OutputTable)
    output = output or DefaultOutput
    indent = indent or "";
    OutputTable = OutputTable or {};

    if (type(val) ~= "table" or OutputTable[val]) then
        if (key and key ~= "") then
            output(string.format("%s%s = %s", indent, tostring(key), tostring(val)));
        else
            output(string.format("%s%s", indent, tostring(val)));
        end
        return 
    end

    if (key and key ~= "") then
        output(string.format("%s%s = %s {", indent, key, tostring(val)));
    else
        output(string.format("%s%s {", indent, tostring(val)));
    end

    OutputTable[val] = true;  -- 表记已输出

    for k, v in pairs(val) do
        Print(v, k, output, indent .. "    ", OutputTable);
    end

    output(string.format("%s}", indent));
end

local function DebugCall(module, ...)
    module = string.upper(module or "DEBUG");

    if (ModuleLogEnableMap[module] == false or (not IsDevEnv and not ModuleLogEnableMap[module])) then return end
    local dateStr, timeStr = commonlib.log.GetLogTimeString();
    local filepos = commonlib.debug.locationinfo(3) or "";
    filepos = string.sub(filepos, 1, 256);
    Print(string.format("\n[%s %s][%s][%s][DEBUG BEGIN]", dateStr, timeStr, module, filepos));

    for i = 1, select('#', ...) do  -->获取参数总数
        Print(select(i, ...));      -->读取参数
    end  

    Print(string.format("[%s %s][%s][%s][DEBUG END]", dateStr, timeStr, module, filepos));
end

setmetatable(Debug, {
    __call = function(self, ...)
        DebugCall(...);
    end
});

function Debug.DisableModule(module)
    ModuleLogEnableMap[module] = false;
end

function Debug.Stack()
    -- 不一定好使
    commonlib.debugstack();
    -- DebugStack()
end

function Debug.Print(...)
    Print(...);
end

function Debug.GetModuleDebug(module)
    if (ModelDebug[module]) then return ModelDebug[module] end

    local obj = {};

    function obj.Enable()
        Debug.EnableModule(module);
    end

    function obj.Disable()
        Debug.DisableModule(module);
    end

    setmetatable(obj, {
        __call = function(obj, ...)
            DebugCall(module, ...);
        end
    });

    -- if (IsDevEnv) then obj.Enable() end

    ModelDebug[module] = obj;

    return obj;
end

function Debug.GetFatalDebug()
    return Debug.GetModuleDebug("FATAL");
end

function Debug.GetErrorDebug()
    return Debug.GetModuleDebug("ERROR");
end

function Debug.GetWarnDebug()
    return Debug.GetModuleDebug("WARN");
end

function Debug.GetInfoDebug()
    return Debug.GetModuleDebug("INFO");
end

function Debug.GetDebugDebug()
    return Debug.GetModuleDebug("DEBUG");
end

function Debug.GetNetDebug()
    return Debug.GetModuleDebug("NET");
end

function _G.DebugStack(dept)
    dept = dept or 50;
    for i = 1, dept do
        local lastInfo = debug.getinfo(i - 1);
        local info = debug.getinfo(i);
        if info then
            print("TraceStack",info.source, info.currentline, lastInfo and lastInfo.name);
        else
            break;
        end
    end
end


-- Debug("v-for", {key=1});

-- Print(true);
-- Print(2);
-- Print("hello world");
-- Print(Print);
-- Print({key = 1}, "test");
-- Print({1,3, {key = 3}, val = 2});
-- local obj = { key = 1};
-- obj.obj = obj;
-- Print(obj);