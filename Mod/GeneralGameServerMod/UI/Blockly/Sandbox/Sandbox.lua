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

local Global = NPL.load("./Global.lua");
local FileManager = NPL.load("../Pages/FileManager");
local Blockly = NPL.load("../Blockly.lua");

local Sandbox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Sandbox:Property("G");
Sandbox:Property("BlocklyInstance");

function Sandbox:ctor()
    self:SetG(Global);
    self:SetBlocklyInstance(Blockly:new());
end

function Sandbox:Init()
    if (self.inited) then return end
    self.inited = true;

	GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
end

function Sandbox:OnWorldLoaded()
    FileManager:SwitchDirectory();
    FileManager:LoadAll();
    local blocklyInstance = self:GetBlocklyInstance();
    FileManager:Each(function(file)
        local text = file.text;
        blocklyInstance:LoadFromXmlNodeText(text);
        local code = blocklyInstance:GetCode();
        -- print("----执行文件代码----", file.filename, code);
        self:ExecCode(code);
    end);
end

function Sandbox:OnWorldUnloaded()

end

function Sandbox:ExecCode(code)
    -- 清空输出缓存区
    Global.ClearOut();

    if (type(code) ~= "string" or code == "") then return Global.GetOut() end
    local func, errmsg = loadstring(code);
    if (not func) then 
        print("===============================Exec Code Error=================================", errmsg) 
        return Global.GetOut();
    end

    setfenv(func, Sandbox:GetG());

    xpcall(function()
        func();
    end, function(errinfo) 
        print("ERROR:", errinfo)
        DebugStack();
    end);

    return Global.GetOut();
end


-- 初始化成单列模式
Sandbox:InitSingleton();