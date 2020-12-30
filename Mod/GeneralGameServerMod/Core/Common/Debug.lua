--[[
Title: Debug
Author(s): wxa
Date: 2020/6/30
Desc: 调试类
use the lib:
-------------------------------------------------------
local Debug = NPL.load("Mod/GeneralGameServerMod/Core/Common/Debug.lua");
-------------------------------------------------------
]]

local Debug = NPL.export()

-- 模块使能映射
local ModuleLogEnableMap = {
    FATAL = true,
    ERROR = true,
    WARN = true,
    INFO = true,
    DEBUG = true,
}

local LogFileName = nil;
local function CheckLogFile()
    if (not IsServer or IsDevEnv) then return end
    local datestr = ParaGlobal.GetDateFormat("yyyy-MM-dd");
    if (LogFileName == datestr) then return end
    LogFileName = datestr;
    
    local logdir = "log/";
    -- 先创建目录
    ParaIO.CreateDirectory(ParaIO.GetCurDirectory(0) .. logdir);
    -- 切换日志文件
    commonlib.servicelog.GetLogger(""):SetLogFile(logdir .. LogFileName .. ".txt");
end

-- debug 实例
local ModelDebug = {};

local function FormatModuleName(module)
    return string.upper(module or "DEBUG");
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

    local plainVal = type(val.ToPlainObject) == "function" and val:ToPlainObject() or val;
    for k, v in pairs(plainVal) do
        Print(v, k, output, indent .. "    ", OutputTable);
    end

    output(string.format("%s}", indent));
end

local function ToString(val, key)
    local text = "";
    local function output(str)
        text = text .. str .. "\n";
    end

    Print(val, key, output);

    return text;
end
Debug.ToString = ToString;

local function LocationInfo(level)
	if not level then level = 1 end
	local res = "";
	level = level+1;
	local info = debug.getinfo(level, "nSl")
	
	if not info then return res end
	
	if info.what == "C" then   
		-- a C function
		res = res.."C function:"
    else   
        local source = commonlib.split(info.source, "\n")[1];
        source = string.gsub(source, "^%s*", "");
        source = string.gsub(source, "%s*$", "");
		-- a Lua function
		if(info.name~=nil) then
			res = res..string.format("%s:%d: in function %s",
							source, info.currentline,tostring(info.name))
		else
			res = res..string.format("%s:%d:", source, info.currentline)
		end					
	end
	return res;
end

local function DebugCall(module, ...)
    CheckLogFile();

    module = FormatModuleName(module);

    if (ModuleLogEnableMap[module] == false or (not IsDevEnv and not ModuleLogEnableMap[module])) then return end
    local dateStr, timeStr = commonlib.log.GetLogTimeString();
    local filepos = LocationInfo(3);
    filepos = string.sub(filepos, 1, 256);
    Print(string.format("\n[%s %s][%s][%s][DEBUG BEGIN]", dateStr, timeStr, module, filepos));

    for i = 1, select('#', ...) do      -->获取参数总数
        local arg = select(i, ...);     -->函数会返回多个值
        if (not GGS.IsDevEnv and GGS.IsServer) then
            Print(arg);                 -- 服务器可以换成压缩的日志格式输出
        else
            Print(arg);                 -->打印参数
        end
    end  

    Print(string.format("[%s %s][%s][%s][DEBUG END]", dateStr, timeStr, module, filepos));
end

setmetatable(Debug, {
    __call = function(self, ...)
        DebugCall(...);
    end
});

function Debug.GetModuleLogEnableMap()
    return ModuleLogEnableMap;
end

function Debug.IsEnableModule(module)
    return ModuleLogEnableMap[FormatModuleName(module)];
end

function Debug.ToggleModule(module)
    module = FormatModuleName(module);
    ModuleLogEnableMap[module] = not ModuleLogEnableMap[module];
end

function Debug.EnableModule(module)
    ModuleLogEnableMap[FormatModuleName(module)] = true;
end

function Debug.DisableModule(module)
    ModuleLogEnableMap[FormatModuleName(module)] = false;
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
    module = FormatModuleName(module);
    
    if (ModelDebug[module]) then return ModelDebug[module] end

    local obj = {};
    local counts = {};   -- 数量控制

    -- 设置指定日志输出次数
    function obj.SetCount(key, count) 
        counts[tostring(key)] = count or 1;
    end

    function obj.Enable()
        Debug.EnableModule(module);
        return obj;
    end

    function obj.Disable()
        Debug.DisableModule(module);
        return obj;
    end

    function obj.If(ok, ...)
        if (not ok) then return end
        DebugCall(module, ...);
    end
    
    function obj.Once(key, ...)
        key = tostring(key)''
        if (counts[key] == 0) then return end
        counts[key] = counts[key] or 1;
        counts[key] = counts[key] - 1;

        DebugCall(...);
    end

    function obj.Format(...)
        DebugCall(module, string.format(...));
        return obj;
    end
    
    function obj.FormatIf(ok, ...)
        if (not ok) then return end
        DebugCall(module, string.format(...));
        return obj;
    end
    
    setmetatable(obj, {
        __call = function(obj, ...)
            DebugCall(module, ...);
        end
    });

    if (ModuleLogEnableMap[module] == nil and IsDevEnv) then obj.Enable() end

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

function _G.DebugStack(dept)
    dept = dept or 50;
    for i = 1, dept do
        local debuginfo = LocationInfo(i);
        if (not debuginfo or debuginfo == "") then break end
        print("TraceStack", debuginfo);

        -- local lastInfo = debug.getinfo(i - 1);
        -- local info = debug.getinfo(i);
        -- if info then
        --     print("TraceStack",info.source, info.currentline, lastInfo and lastInfo.name);
        -- else
        --     break;
        -- end
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