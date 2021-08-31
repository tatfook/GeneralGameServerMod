--[[
Title: BlockAPI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local BlockAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/BlockAPI.lua");
------------------------------------------------------------
]]


local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local BlockAPI = NPL.export();

local function LoadTemplate(path, x, y, z)
    local filename = path;
    
    if (not filename or filename == "") then filename = "default" end
    if(not filename:match("%.blocks%.xml$")) then filename = filename..".blocks.xml" end

    local fullpath = Files.GetWorldFilePath(filename) or (not filename:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/"..filename));

    if (fullpath) then
        local task = BlockTemplate:new({
            operation = BlockTemplate.Operations.Load, 
            filename = fullpath,
            blockX = x,
            blockY = y, 
            blockZ = z, 
            bSelect=nil, 
            load_anim_duration=0,
            UseAbsolutePos = true,
            TeleportPlayer=false,
        });
        task:Run();
    else
        LOG.std(nil, "info", "loadtemplate", "file %s not found", filename);
    end
end

setmetatable(BlockAPI, {__call = function(_, CodeEnv)
    CodeEnv.GetBlockId = ParaTerrain.GetBlockTemplateByIdx;
    CodeEnv.GetBlockEntity = EntityManager.GetBlockEntity;
	CodeEnv.CreateBlockPieces = function (blockid, ...) return GameLogic.GetWorld():CreateBlockPieces(block_types.get(blockid), ...) end
	CodeEnv.SetBlock = function(...) BlockEngine:SetBlock(...) end
    CodeEnv.GetBlock = function(...) return BlockEngine:GetBlock(...) end 
	CodeEnv.GetBlockFull = function (...) return BlockEngine:GetBlockFull(...) end
    CodeEnv.ConvertToRealPosition = function (...) return BlockEngine:ConvertToRealPosition_float(...) end
    CodeEnv.ConvertToBlockPosition = function(x, y, z) return BlockEngine:block(x, y, z) end
	CodeEnv.ConvertToBlockIndex = function (...) return BlockEngine:GetSparseIndex(...) end
	CodeEnv.ConvertToBlockPositionFromBlockIndex = function (...) return BlockEngine:FromSparseIndex(...) end
    CodeEnv.LoadTemplate = LoadTemplate;


    CodeEnv.__BlockSize__ = BlockEngine.blocksize;
    CodeEnv.__HalfBlockSize__ = BlockEngine.half_blocksize;
end});