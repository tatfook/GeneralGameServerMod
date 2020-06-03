
NPL.load("(gl)script/ide/STL.lua");

local Agent = commonlib.gettable("ParacraftServer.Agent");

function Agent:New(o) 
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

function Agent:SetId(id)
    self.id = id;
end

function Agent:GetId() 
    return self.id;
end

-- 响应客户端数据
function Agent:Reply(msg) 
    local interface_file = msg.interface_file or "interface.lua";
    local addr = self.GetId();
    NPL.activate(string.format("%s:%s", addr, interface_file), msg);
end

function Agent:SetPosition(msg)
    --if (not pos or not pos.x or not pos.y or not pos.z) then
        --LOG.std(nil, "error", "agent", "位置信息不合法");
        --LOG.error(pos);
    --end

    self.pos = pos;

    -- 发送位置更新到相关客户端
    self.agent_manager:Each(function(agent)
        if (agent:GetId() == self:GetId()) then return end

        agent:Reply({
            cmd: "set-agent-position",
            interface_file: data.interface_file,
            data: msg.data,
        });
    end)
end
