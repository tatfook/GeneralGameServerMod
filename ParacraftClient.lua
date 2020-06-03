
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

local main_state = nil
local function activate() 
    if (main_state == 0) then 
        --NPL.activate("ParacraftServer:ParacraftServer.lua", {type="post", count=count});
        return;
    end

    NPL.AddPublicFile("interface.lua", 1);
    NPL.StartNetServer("0", "0");

    -- 添加服务器地址
    NPL.AddNPLRuntimeAddress({host="127.0.0.1", port="9000", nid="ParacraftServer"});

    LOG.std(nil, "info", "ParacraftClient", "started");

    local count = 0;
    while(NPL.activate("(main)ParacraftServer:interface.lua", {
        cmd = "echo",
        data = "hello world",
    }) ~= 0 and count < 10) do 
        echo("failed to send message");
        ParaEngine.Sleep(1);
        count = count + 1;
    end

    main_state = 0;
end

NPL.this(activate);

