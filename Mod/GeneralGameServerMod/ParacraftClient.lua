
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

local interface_file = "ParacraftClient.lua";
local main_state = 0  -- 0 初始态

local function init() 
    -- 暴露接口文件
    NPL.AddPublicFile(interface_file, 1);

    -- 启动服务
    NPL.StartNetServer("0", "0");

    -- 添加服务器地址
    NPL.AddNPLRuntimeAddress({host="127.0.0.1", port="9000", nid="ParacraftServer"});

    LOG.std(nil, "info", "ParacraftClient", "客户端启动");

    -- 与服务器建立 TCP 连接
    local tryCount = 0;
    while(NPL.activate("(main)ParacraftServer:interface.lua", {
        cmd = "echo",
        data = "hello world",
        interface_file = interface_file,
    }) ~= 0 and tryCount < 10) do 
        echo("建立失败, 1秒重试...");
        ParaEngine.Sleep(1);
        tryCount = tryCount + 1;
    end

    if (tryCount >= 10) then
        LOG.std(nil, "info", "ParacraftServer", "与服务器建立TCP链接失败");
        return false;
    end

    LOG.std(nil, "info", "ParacraftServer", "与服务器成功建立TCP链接");

    return true;
end

-- 发送服务器消息
local function sendMsg(msg) 
    local ret = NPL.activate("(main)ParacraftServer:interface.lua", msg);
    if (ret ~= 0) then
        LOG.std(nil, "info", "ParacraftClient", "发送消息失败");
    end
end

-- 处理服务器发送过啦的消息
local function handleMsg(msg) 
    LOG.std(nil, "info", "ParacraftClient", "收到服务器消息:");
    LOG.debug(msg);
end

local function activate() 
    -- main_state 为 0 初始化客户端并与服务器建立链接
    if (main_state == 0) then 
        if (init()) then 
            main_state = 1;
        end

        return;
    end

    -- main_state 为 1 链接已建立与服务正常通信交流
    if (main_state == 1 and msg and msg.cmd) then
        handleMsg(msg);
    end

    -- main loop
    if (main_state == 1 and not msg) then
        sendMsg({
            cmd = "set-agent-position",
            data = {
                x = 1,
                y = 2, 
                z = 3,
            }
        })
    end
end

NPL.this(activate);

----NPL.activate("ParacraftServer:ParacraftServer.lua", {type="post", count=count});
--return;
