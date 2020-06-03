
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

local function activate()
    if(initialized) then
        return;
	end

    initialized = true;

    NPL.AddPublicFile("test.lua", 1);
    
    NPL.StartNetServer("0.0.0.0", "9000");
	
    LOG.std(nil, "info", "Server", "server is started with %d threads", nServerThreadCount);
end

NPL.this(activate);
