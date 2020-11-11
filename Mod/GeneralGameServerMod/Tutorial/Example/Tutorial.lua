--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导API 
-----------------------------------------------
local Tutorial = NPL.load("Mod/GeneralGameServerMod/Tutorial/Tutorial.lua");
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
local TutorialContext = NPL.load("./TutorialContext.lua", IsDevEnv);
local Page = NPL.load("./Page/Page.lua", IsDevEnv);

local Tutorial = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Tutorial:Property("CodeEnv");          -- 代码执行环境
Tutorial:Property("CodeBlock");        -- 代码方块
Tutorial:Property("Level");
Tutorial:Property("Context");
Tutorial:Property("LeftClickToDestroyBlockStrategy", {}); -- 配置左击删除方块策略
Tutorial:Property("RightClickToCreateBlockStrategy", {}); -- 配置右击创建方块策略

function Tutorial:ctor()
    self.entities = {};  -- 实体列表
end

function Tutorial:Init(codeblock)
    self:SetCodeBlock(codeblock);
    self:SetCodeEnv(codeblock:GetCodeEnv());
    self:SetContext(TutorialContext:new():Init(self));
    -- self:SetLevel(Levels.GetLevel("Level_0"):new():Init(self));

    self.canDestroyBlockStrategy = {};

    self:GetContext():activate();
    return self;
end

-- 获取Page
function Tutorial:GetPage()
    return Page;
end

-- 激活教学上下文
function Tutorial:ActiveTutorialContext()
    self:GetContext():activate();
end

-- 左击是否可以删除
function Tutorial:IsCanLeftClickToDestroyBlock(data)
    local strategy = self:GetLeftClickToDestroyBlockStrategy();
    if (type(strategy) ~= "table") then return end

    for _, obj in ipairs(strategy) do 
        if (obj.type == "BlockPos" and obj.blockX == data.blockX and obj.blockY == data.blockY and obj.blockZ == data.blockZ) then return true end
        if (obj.type == "BlockId" and obj.blockId == data.blockId) then return true end
    end

    return false;
end

-- 右击是否可以创建
function Tutorial:IsCanRightClickToCreateBlock(data)
    local strategy = self:GetRightClickToCreateBlockStrategy();
    if (type(strategy) ~= "table") then return end

    for _, obj in ipairs(strategy) do 
        if (obj.type == "BlockPos" and obj.blockX == data.blockX and obj.blockY == data.blockY and obj.blockZ == data.blockZ) then return true end
        if (obj.type == "BlockId" and obj.blockId == data.blockId) then return true end
    end

    return false;
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