
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included
NPL.load("(gl)script/ide/System/os/GetUrl.lua");

NPL.load("./agent_manager.lua");

local AgentManager = commonlib.gettable("ParacraftServer.AgentManager");
local string_format = string.format;

local agent_manager = AgentManager:New(commonlib.gettable("ParacraftServer.AgentManagerInst"));

local function activate() 
    if (not msg or not msg.cmd) then return end;

    local cmd = msg.cmd;
    local data = msg.data;

    -- 获取客户端代理
    local agent = agent_manager:GetAgentById(msg.tid or msg.nid);

    LOG.std(nil, "debug", "interface", "收到客户端消息");
    LOG.debug(msg);

    if (cmd == "echo") then
        return NPL.activate(agent:GetActivateAddr(msg), msg);
    elseif (msg.tid and cmd == "authenticate") then
        -- 客户端认证
        if (msg.username == "xiaoyao" and msg.password == "123456") then 
            -- 认证成功
            local nid = AgentManager:TidToNid(msg.tid);
            NPL.accept(msg.tid, nid);
        else
            NPL.reject(msg.tid);
        end
    elseif (cmd == "set-agent-position" and msg.nid) then 
        -- 同步位置信息
        agent:SetPosition(msg);
    else 
        LOG.std(nil, "info", "interface", "invalid cmd: %s", msg.cmd);
    end
end

NPL.this(activate);


