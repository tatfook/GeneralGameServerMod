
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

-- this can be modified via https://keepwork.com/official/paracraft/config/PluginManager 
local ds_url = "https://api.keepwork.com/core/v0/repos/official%2Fparacraft/files/official%2Fparacraft%2Fconfig%2FPluginManager.md";

PluginManager.PluginList = {
    -- {
    --     name = "MineCraft 地图导入导出插件",
    --     desc = "支持导入 MineCraft 世界, 以及 Schematics 地图文件",
    --     url = "https://ghproxy.com/https://github.com/tatfook/mc/releases/download/v1.0.0/MCImporter.zip",
    --     key = "MCImporter.zip",
    -- },
}

function PluginManager:GetLoader()
	return ModManager:GetLoader();
end

function PluginManager:LoadDataSource()
    if (self.loaded) then return end;
    self.loaded = true;
    local plugins = {};
    System.os.GetUrl(ds_url, function(status_code, msg, data)
        if (status_code ~= 200) then return end 

        local lines = commonlib.split(data, "\n");
        for _, line in ipairs(lines) do
            local url = string.match(line, "http[s]?://[^#]+");
            local name = string.match(line, "#name=([^#]+)");
            local desc = string.match(line, "#desc=([^#]+)");
            local key = string.match(line, "#key=([^#]+)");
            local project_url = string.match(line, "#project_url=([^#]+)");
            if (url and key and name) then
                -- print(url, name, key, desc)
                plugins[key] = {url = url, name = name, desc = desc or "", key = key, project_url = project_url};
            end
        end

        for _, plugin in pairs(plugins) do
            plugin.path = CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory() .. "/Mod/" .. plugin.key);
            if (not string.match(plugin.path, "%.zip$")) then plugin.path = plugin.path .. ".zip" end
            plugin.state = CommonLib.IsExistFile(plugin.path) and 1 or 0;
    
            table.insert(self.PluginList, plugin);
        end

        if (self.__ui__) then self.__ui__:GetG():RefreshWindow() end 
    end);
end

function PluginManager:Init()
    return self;
end

function PluginManager:Show()
    self:Close();
    self:LoadDataSource();
    self.__ui__ = Page.Show({
        PluginList = self.PluginList,
        ClickInstallPlugin = function(plugin)
            self:InstallPlugin(plugin);
        end
    }, {
        url = "Mod/GeneralGameServerMod/Command/PluginManager/PluginManager.html",
        width = 647,
        height = 437,
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