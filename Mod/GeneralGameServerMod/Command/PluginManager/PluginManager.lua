
--[[
Title: PluginManager
Author(s):  wxa
Date: 2020-06-12
Desc: Command
use the lib:
------------------------------------------------------------
local PluginManager = NPL.load("Mod/GeneralGameServerMod/Command/PluginManager/PluginManager.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
local ModManager = commonlib.gettable("Mod.ModManager");
local FileDownloader = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader"));
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

local PluginManager =  commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

PluginManager.PluginList = {
    {
        name = "MineCraft 地图导入导出插件",
        desc = "支持导入 MineCraft 世界, 以及 Schematics 地图文件",
        url = "https://ghproxy.com/https://github.com/tatfook/mc/releases/download/v1.0.0/MCImporter.zip",
        key = "MCImporter.zip",
    },
}

function PluginManager:GetLoader()
	return ModManager:GetLoader();
end

function PluginManager:Init()
    for _, plugin in ipairs(self.PluginList) do
        plugin.path = CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory() .. "/Mod/" .. plugin.key);
        if (not string.match(plugin.path, "%.zip$")) then plugin.path = plugin.path .. ".zip" end
        plugin.state = CommonLib.IsExistFile(plugin.path) and 1 or 0;
    end

    -- local xmlRoot = ParaXML.LuaXML_ParseFile(CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory() .. "/Mod/ModsConfig.xml"));
    -- local mods = commonlib.XPath.selectNodes(xmlRoot, "/mods/mod") or {};
    -- for _, mod in ipairs(mods) do
    --     local modname = mod.attr and mod.attr.name;
    --     for _, plugin in ipairs(self.PluginList) do
    --         if (plugin.key == modname) then
    --             if (type(mod[0]) == "table" and mod[0].name == "world" and type(mod[0].attr) == "table" and mod[0].attr.checked) then
    --                 plugin.state = 1;
    --             end
    --         end
    --     end
    -- end

    return true;
end

function PluginManager:Show()
    self:Close();
    self.__ui__ = Page.Show({
        PluginList = self.PluginList,
        ClickInstallPlugin = function(plugin)
            self:InstallPlugin(plugin);
        end
    }, {
        url = "Mod/GeneralGameServerMod/Command/PluginManager/PluginManager.html",
        width = 750,
        height = 540,
        draggable = false,
        OnClose = function()
            self.__ui__ = nil;
        end
    });
end

function PluginManager:Close()
    if (not self.__ui__) then return end
    self.__ui__:CloseWindow();
    self.__ui__ = nil;
end


function PluginManager:InstallPlugin(plugin)
    local url, key, path = plugin.url, plugin.key, plugin.path;
    ParaIO.DeleteFile(path);
    FileDownloader:new():Init(key, url, path, function(bSucceed, filename) 
        if (bSucceed) then
            plugin.state = 1;
            -- self.__ui__:GetG().RefreshWindow();
            self:GetLoader():Refresh();
            -- self:GetLoader():GetPluginLoader():EnablePlugin(key, true);
        else
            CommandManager:RunCommand("/tip 无法下载插件: " .. key); 
        end
    end);
end

PluginManager:InitSingleton():Init();