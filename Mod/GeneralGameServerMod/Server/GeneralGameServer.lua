
NPL.load("Mod/GeneralGameServerMod/Common/Packets.lua");

local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local GeneralGameServer = commonlib.gettable("Mod.GeneralGameServerMod.Server.GeneralGameServer");

GeneralGameServer.config = {
    host = "0.0.0.0",
    port = "9000",
    log_level="INFO",
}

function GeneralGameServer:ctor() 
    self.inited = false;
    self.isStart = false;
end

function GeneralGameServer:LoadNetworkSettings()
	local att = NPL.GetAttributeObject();
	att:SetField("TCPKeepAlive", true);
	att:SetField("KeepAlive", false);
	att:SetField("IdleTimeout", false);
	att:SetField("IdleTimeoutPeriod", 1200000);
	NPL.SetUseCompression(true, true);
	att:SetField("CompressionLevel", -1);
	att:SetField("CompressionThreshold", 1024*16);
	
	att:SetField("UDPIdleTimeoutPeriod", 1200000);
	att:SetField("UDPCompressionLevel", -1);
	att:SetField("UDPCompressionThreshold", 1024*16);
	-- npl message queue size is set to really large
	__rts__:SetMsgQueueSize(5000);
end

function GeneralGameServer:Init() 
    if (self.inited) then return end;
    
    -- 设置系统属性
    self:LoadNetworkSettings();

    -- Connections:Init();
    NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
    local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
	Connections:Init();

    -- 初始化网络包
	Packets:StaticInit();

    -- 暴露接口文件
    NPL.AddPublicFile("Mod/GeneralGameServerMod/Common/Connection.lua", 401);
    
    self.inited = true;
    return self;
end

-- 加载配置
function GeneralGameServer:load_config(filename) 
    -- 加载配置文件
    local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
    if (not xmlRoot) then
		LOG.std(nil, "error", "ParacraftServer", "failed loading paracraft server config file %s", filename);
        return;
    end

    LOG.std(nil, "info", "ParacraftServer", xmlRoot);

    local config_node = commonlib.XPath.selectNodes(xmlRoot, "/ParacraftServer/config")[1];
    LOG.std(nil, "", "ParacraftServer", config_node);
    if (config_node and config_node.attr) then 
        commonlib.partialcopy(self.config, config_node.attr);
    end

    -- 设置日志级别
    --LOG.level = self.config.log_level;
end

-- 启动服务
function GeneralGameServer:Start() 
    if (self.isStart) then return end;

    -- 初始化
    self:Init();

    -- 加载配置
    -- self:load_config(ParaEngine.GetAppCommandLineByParam("config_file", "config.xml"));

    -- 启动服务
    NPL.StartNetServer(self.config.host, self.config.port);

    LOG.std(nil, "info", "GeneralGameServer", "服务器启动");

    self.isStart = true;
end
