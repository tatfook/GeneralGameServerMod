
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included
NPL.load("(gl)script/ide/System/os/GetUrl.lua");

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

    -- 启动服务
    NPL.StartNetServer(self.config.host, self.config.port);

    LOG.std(nil, "info", "ParacraftServer", "服务器启动");
end


-- main loop 
local isStart = false;
local function activate() 
    if (isStart) then return end

    isStart = true;

    ParacraftServer:Start();
end


NPL.this(activate)

--local function authenticate(token) 
    --local err, msg, data = System.os.GetUrl({
        --url = "https://api.keepwork.com/core/v0/user/authenticated",
        --json = true,
        --form = {
            --token = token,
        --},
        --method = "POST",
    --});
    --LOG.std(nil, "info", "test", err);
    --LOG.std(nil, "info", "test", msg);
    --LOG.std(nil, "info", "test", data);
--end

--authenticate("eyJhbGciOiJIUzEiLCJ0eXAiOiJKV1QifQ.eyJ1c2VySWQiOjMsInJvbGVJZCI6MCwidXNlcm5hbWUiOiJ4aWFveWFvIiwiZXhwIjoxNTkzNzcwMDAyLjI2MX0.T1hqbXJRRTVXSHQrMVFQV3V0WHp2OHIzdmRJPQ");


