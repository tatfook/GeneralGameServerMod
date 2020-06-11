local GeneralGameServer = commonlib.gettable("GeneralGameServerMod.Server.GeneralGameServer");

GeneralGameServer.config = {
    host = "0.0.0.0",
    port = "9000",
    log_level="INFO",
}

function GeneralGameServer:ctor() 
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

function GeneralGameServer:init() 
    self:LoadNetworkSettings();
    
    -- 初始化网络包
    NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet_Types.lua");
	local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");
	Packet_Types:StaticInit();

    -- 暴露接口文件
    NPL.AddPublicFile("script/apps/Aries/Creator/Game/Network/ConnectionBase.lua", 201);
    
    -- 启动Server前重写网络处理逻辑
    NPL.load("Mod/GeneralGameServerMod/Server/NetServerHandler.lua");

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
    self:init();

    -- 加载配置
    -- self:load_config(ParaEngine.GetAppCommandLineByParam("config_file", "config.xml"));

    -- 启动服务
    NPL.StartNetServer(self.config.host, self.config.port);

    LOG.std(nil, "info", "GeneralGameServer", "服务器启动");

    self.isStart = true;
end