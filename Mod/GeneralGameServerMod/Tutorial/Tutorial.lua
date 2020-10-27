--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导API 
-----------------------------------------------
local Tutorial = NPL.load("Mod/GeneralGameServerMod/Tutorial.lua");
local tutorial = Tutorial:new():Init(codeblock);
-----------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNPC.lua");
local EntityNPC = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Levels = NPL.load("./Level/Levels.lua", IsDevEnv);
local Tutorial = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Tutorial:Property("CodeEnv");          -- 代码执行环境
Tutorial:Property("CodeBlock");        -- 代码方块
Tutorial:Property("Level");

function Tutorial:ctor()
    self.entities = {};  -- 实体列表
end

function Tutorial:Init(codeblock);
    self:SetCodeBlock(codeblock);
    self:SetCodeEnv(codeblock:GetCodeEnv());
    
    self:SetLevel(Levels.GetLevel("Level_0"):new():Init(self));
    return self;
end

-- 获取块ID
function Tutorial:GetBlockId(...)
    return ParaTerrain.GetBlockTemplateByIdx(...);
end

-- 获取块实体
function Tutorial:GetBlockEntity(...)
    return EntityManager.GetBlockEntity(...)
end

function Tutorial:CreateBlockPieces(blockid, ...)
    local block_template = block_types.get(blockid)
	return GameLogic.GetWorld():CreateBlockPieces(block_template, ...) ;
end

-- 设置方块
function Tutorial:SetBlock(...)
    return BlockEngine:SetBlock(...);
end

function Tutorial:GetBlockFull(...) 
    return BlockEngine:GetBlockFull(...);
end

function Tutorial:LoadTemplate(path, x, y, z)
    local filename = path;
    if(not filename:match("%.blocks%.xml$")) then filename = filename..".blocks.xml" end
    local fullpath = Files.GetWorldFilePath(filename) or (not filename:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/"..filename));
    if(fullpath) then
        local task = BlockTemplate:new({
            operation = BlockTemplate.Operations.Load, 
            filename = fullpath,
            blockX = x, blockY = y, blockZ = z, bSelect = nil, load_anim_duration = 0,
            UseAbsolutePos = true,
            TeleportPlayer=false,
        });
        task:Run();
    else
        LOG.std(nil, "info", "loadtemplate", "file %s not found", filename);
    end
end

function Tutorial:GetPlayerId()
    return EntityManager.GetPlayer().entityId;
end

function Tutorial:GetAllEntities(...)
    return EntityManager.GetAllEntities(...);
end

function Tutorial:GetEntityById(...)
    return EntityManager.GetEntityById(...);
end

function Tutorial:GetEntitiesInBlock(...)
    return EntityManager.GetEntitiesInBlock(...);
end

function Tutorial:GetPlayer()
    return EntityManager.GetPlayer();
end

function Tutorial:CreateNPC(...)
    local npc = EntityNPC:Create(...);
    npc:Attach();
    table.insert(self.entities, npc);
    return npc;
end

-- register("CreateEntity", function (bx,by,bz, path, canBeCollied)
--     NPL.load("scrtip/Truck/Game/Entity/EntityCustom.lua")
--     local EntityCustom = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCustom");
--     local entity = EntityCustom:Create({bx = bx, by = by, bz = bz, mModel = path or "" , mEnablePhysics = canBeCollied});
--     table.insert(environment.__entities, entity);
--     return entity;
-- end)

function Tutorial:IsInWater()
    return GameLogic.GetPlayerController():IsInWater();
end

function Tutorial:IsInAir() 
    return GameLogic.GetPlayerController():IsInAir();
end
    
function Tutorial:GetAssetID()
end
    
function Tutorial:GetName() 
end