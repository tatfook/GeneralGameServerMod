
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

local AgentManager = commonlib.gettable("ParacraftServer.AgentManager");
local string_format = string.format;

local agent_manager = AgentManager:new(commonlib.gettable("ParacraftServer.AgentManagerInst"));

local function activate() 
    if (not msg or not msg.cmd) then return end;

    local cmd = msg.cmd;
    local data = msg.data;

    -- 获取客户端代理
    local agent = agent_manager:GetAgentById(msg.tid or msg.nid);

    LOG.std(nil, "debug", "interface", msg);


    if (cmd == "echo") then
        NPL.activate(string_format("%s:%s", msg.tid or msg.nid, reply_file), {
            cmd = "echo_reply",
            data = msg.data,
        });
        return;
    elseif (msg.tid and cmd == "auth") then
        -- 客户端认证
        if (msg.username == "xiaoyao" and msg.password == "123456") then 
            -- 认证成功
            local nid = AgentManager:TidToNid(msg.tid);
            NPL.accept(msg.tid, nid);
        else
            NPL.reject(msg.tid);
        end
    elseif (cmd == "position" and msg.nid) then 
        -- 同步位置信息
        agent:SetPosition(msg);
    else 
        LOG.std(nil, "info", "interface", "invalid cmd: %s", msg.cmd);
    end
end

NPL.this(activate);


