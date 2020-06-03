
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

local ParacraftServer = commonlib.gettable("ParacraftServer");

ParacraftServer.config = {
    host = "0.0.0.0",
    port = "9000",
    log_level="INFO",
}
-- 接口文件
function ParacraftServer:AddPublicFiles() 
    NPL.AddPublicFile("interface.lua", 1);
end

-- 加载配置
function ParacraftServer:load_config(filename) 
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
function ParacraftServer:Start() 
    -- 加载配置
    self:load_config(ParaEngine.GetAppCommandLineByParam("config_file", "config.xml"));

    -- 暴露通信文件
    self:AddPublicFiles();

    NPL.StartNetServer(self.config.host, self.config.port);

    LOG.std(nil, "info", "ParacraftServer", "start paracraft server");
end


-- main loop 
local isStart = false;
local function activate() 
    if (isStart) then return end

    isStart = true;

    ParacraftServer:Start();
end


NPL.this(activate)
