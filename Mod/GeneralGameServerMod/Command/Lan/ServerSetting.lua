--[[
Title: ServerSetting
Author(s):  wxa
Date: 2020-06-12
Desc: ServerSetting
use the lib:
------------------------------------------------------------
local ServerSetting = NPL.load("Mod/GeneralGameServerMod/Command/Lan/ServerSetting.lua");
------------------------------------------------------------
]]

local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua", IsDevEnv);

local ServerSetting =  commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ServerSetting:InitSingleton();

ServerSetting:Property("Lan");
ServerSetting:Property("EnableLocalServer", false, "IsEnableLocalServer");
ServerSetting:Property("LocalServerIp");
ServerSetting:Property("LocalServerPort", "8099");
ServerSetting:Property("RemoteServerIp");
ServerSetting:Property("RemoteServerPort", "8099");

function ServerSetting:ShowUI()
    if (self.__ui__) then return end 

    self.__ui__ = Page.Show({
        __server_setting__ = self,
        OnClose = function()
            self.__ui__ = nil;
            -- self:CheckServer();
            self:SaveConfig();
        end
    }, {
        url = "Mod/GeneralGameServerMod/Command/Lan/ServerSetting.html",
        width = 700,
        height = 500,
    });
end

function ServerSetting:CloseUI()
    if (not self.__ui__) then return end 
    self.__ui__:CloseWindow();
    self.__ui__ = nil;
end

function ServerSetting:CheckServer()
    if (self:IsEnableLocalServer()) then
        self:GetLan():StartServer(self:GetLocalServerIp(), self:GetLocalServerPort());
        self:GetLan():SetServer(true);
    else 
        self:GetLan():SetServer(false);
    end

    if (self:GetRemoteServerIp()) then
        self:GetLan():SetServerIp(self:GetRemoteServerIp());
        self:GetLan():SetServerPort(self:GetRemoteServerPort());
        self:GetLan():SetClient(true);
        self:GetLan():SetEnableSnapshot(true);  -- 客户端默认开启发送截屏功能
        self:GetLan():StartClient(self:GetRemoteServerIp(), self:GetRemoteServerPort());
    end
end


function ServerSetting:LoadConfig()
    local config = GameLogic.GetPlayerController():LoadLocalData("__lan_server_setting__", nil, true);
    if (not config) then return end 

    self:SetEnableLocalServer(config.EnableLocalServer);
    self:SetRemoteServerIp(config.RemoteServerIp);
    self:SetRemoteServerPort(config.RemoteServerPort);
end

function ServerSetting:SaveConfig()
    local config = {
        EnableLocalServer = self:IsEnableLocalServer(),
        RemoteServerIp = self:GetRemoteServerIp(),
        RemoteServerPort = self:GetRemoteServerPort(),
    };

    return GameLogic.GetPlayerController():SaveLocalData("__lan_server_setting__", config, true, false);
end

function ServerSetting:Init()
    self:LoadConfig();
    return self;
end

ServerSetting:InitSingleton():Init();