

NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

local function activate()
    if(initialized) then
        return;
	end

    initialized = true;

	NPL.StartNetServer("0", "0");

	-- add the server address
	NPL.AddNPLRuntimeAddress({host="127.0.0.1", port="9000", nid="simpleserver"})
	
    LOG.std(nil, "info", "Client", "started");

    while( NPL.activate("(main)simpleserver:test.lua", {TestCase = "TP", data="from client"}) ~=0 ) do
        echo("failed to send message");
        ParaEngine.Sleep(1);
    end
end

NPL.this(activate);
