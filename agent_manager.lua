
NPL.load("(gl)script/ide/STL.lua");

NPL.load("./agent.lua");

local Agent = commonlib.gettable("ParacraftServer.Agent");
local AgentManager = commonlib.gettable("ParacraftServer.AgentManager");

local tid_agent_map = {};
local nid_agent_map = {};
local next_id = 0;

function AgentManager:New(o) 
	o = o or {}  
	setmetatable(o, self)
	self.__index = self
	return o
end

-- 获取唯一ID
function AgentManager:GetNextID() 
    next_id = next_id + 1;
    --return next_id;
    return string.format("__%d__", next_id);  -- 区别tid 和 nid
end

function AgentManager:NewAgent(id) 
    local agent = Agent:New();
    agent:SetId(id);
    agent.agent_manager = self;
    return agent;
end

function AgentManager:GetAgentByTid(tid) 
    if (not tid) then 
        return; 
    end

    if (tid_agent_map[tid]) then
        return tid_agent_map[tid]; 
    end

    local agent = self:NewAgent(tid);

    tid_agent_map[tid] = agent;
    return tid_agent_map[tid];
end

function AgentManager:DeleteAgentByTid(tid)
    tid_agent_map[tid] = nil
end

function AgentManager:GetAgentByNid(nid) 
    if (not nid) then 
        return; 
    end

    if (nid_agent_map[nid]) then
        return nid_agent_map[nid]; 
    end

    local agent = self:NewAgent(nid);

    nid_agent_map[nid] = agent;
    return nid_agent_map[nid];
end

function AgentManager:DeleteAgentByNid(nid) 
    nid_agent_map[nid] = nil
end

function AgentManager:GetAgentById(id)
    return self:GetAgentByTid(id) or self:GetAgentByNid(id);
end

function AgentManager:TidToNid(tid) 
    local agent = self:GetAgentByTid(tid);
    local nid = self:GetNextID();

    tid_agent_map[tid] = nil
    agent:SetId(nid);
    nid_agent_map[nid] = agent;

    return nid;
end

function AgentManager:Each(func) 
    for key, val in pairs(tid_agent_map) do
        func(val);
    end
end
