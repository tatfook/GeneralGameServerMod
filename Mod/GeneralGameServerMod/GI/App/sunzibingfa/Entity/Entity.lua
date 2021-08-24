
local Entity = inherit(require("Entity"), module());

-- local __all_entity__ = {};

function Entity:Init(...)
    Entity._super.Init(self, ...);

    -- table.insert(__all_entity__, self);

    return self;
end

function Entity:SetDefaultSkillPeerBlood(blood)
end

function Entity:SetDefaultSkillRadius()
end
-- function GetAllEntity()
--     return __all_entity__;
-- end

-- function DestroyAllEntity()
--     for _, entity in ipairs(__all_entity__) do
--         entity:Destroy();
--     end
--     __all_entity__ = {};
-- end
