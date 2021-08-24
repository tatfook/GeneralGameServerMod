
--[[
Title: CodeEnv
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡代码环境
]]

local API = module();

local G = {};
local __level__ = nil;

function API.SetG(g)
    G = g;
end

function API.SetLevel(level)
    __level__ = level;
end

function API.MoveForward(entity_name, ...)
    G[entity_name]:MoveForward(...);
end

function API.TurnLeft(entity_name, ...)
    G[entity_name]:TurnLeft(...);
end

function API.TurnRight(entity_name, ...)
    G[entity_name]:TurnRight(...);
end

local BuildType = {
    bridge = 126 ,-- {class = "bridge",  maxHealth=50, offsetZ = -1},
    air = 0, 
    fence = -1,
}
function API.Build(entity_name, build_type)
    local entity = G[entity_name];
    if (build_type == "bridge" or build_type == "air") then
        return entity:Build(BuildType[build_type]);
    end
    if (build_type == "fence") then
        local x, y, z = entity:GetBlockPos();
        local facing = entity:GetFacing();
        x = x + math.floor(math.cos(facing)+0.5);
        z = z - math.floor(math.sin(facing)+0.5);
        __level__:CreateCrossFenceEntity(x, y, z);    
    end
end

function API.Attack(entity_name, ...)
    local entity = G[entity_name];
    local facing = entity:GetFacing();
    entity:Attack(...);
    sleep(entity:GetDefaultSkill():GetSkillInterval());
    entity:SetFacing(facing);
end
